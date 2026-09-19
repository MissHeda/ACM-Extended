// ACME hands-free ragdoll drag handle.
// Physics stays patient-owner authoritative; provider locomotion is local; the rope/harness is a client-side
// visualization reconstructed from public transaction state, so JIP needs no persistent visual objects.
if (missionNamespace getVariable ["ACME_dragHandle_runtimeInstalled",false]) exitWith {};
missionNamespace setVariable ["ACME_dragHandle_runtimeInstalled",true];

// First-pass tuning. All are missionNamespace values on purpose so they can be dialed in live without changing
// transaction structure.
if (isNil "ACME_dragHandle_enabled") then {ACME_dragHandle_enabled = true;};
if (isNil "ACME_dragHandle_attachDistance") then {ACME_dragHandle_attachDistance = 2.3;};
if (isNil "ACME_dragHandle_slackLength") then {ACME_dragHandle_slackLength = 1.0;};
if (isNil "ACME_dragHandle_releaseDistance") then {ACME_dragHandle_releaseDistance = 2.65;};
if (isNil "ACME_dragHandle_springAccelPerM") then {ACME_dragHandle_springAccelPerM = 8.0;};
if (isNil "ACME_dragHandle_damping") then {ACME_dragHandle_damping = 2.1;};
if (isNil "ACME_dragHandle_maxAccel") then {ACME_dragHandle_maxAccel = 5.2;};
if (isNil "ACME_dragHandle_lightAnimCoef") then {ACME_dragHandle_lightAnimCoef = 0.62;};
if (isNil "ACME_dragHandle_heavyAnimCoef") then {ACME_dragHandle_heavyAnimCoef = 0.48;};

["ACME_dragHandle_startAck",{
    params ["_medic","_patient","_ok","_weight",["_reason",""],["_session",""]];
    if (isNull _medic || {!local _medic}) exitWith {};
    _medic setVariable ["ACME_dragHandle_pending",false];
    if (_ok) then {
        // Seed the authoritative values locally before applying provider restrictions. Public-variable replication
        // and the targeted acknowledgement use different network paths and are not required to arrive in lockstep.
        if (_session != "" && {(_medic getVariable ["ACME_dragHandle_lastStoppedSession",""]) == _session}) exitWith {};
        _patient setVariable ["ACME_dragHandle_active",true];
        _patient setVariable ["ACME_dragHandle_dragger",_medic];
        _patient setVariable ["ACME_dragHandle_weight",_weight];
        _patient setVariable ["ACME_dragHandle_session",_session];
        [_medic,_patient,_weight,_session] call ACME_fnc_dragHandleStartMedic;
    } else {
        if (_reason != "") then {[_reason,1.8,_medic,12] call ace_common_fnc_displayTextStructured;};
    };
}] call CBA_fnc_addEventHandler;

["ACME_dragHandle_stopped",{
    params ["_medic","_patient",["_reason","manual"],["_session",""]];
    if (!isNull _medic && {local _medic}) then {
        if (_session != "") then {_medic setVariable ["ACME_dragHandle_lastStoppedSession",_session];};
        [_medic,_patient,_reason,_session] call ACME_fnc_dragHandleStopMedic;
    };
}] call CBA_fnc_addEventHandler;

// Advanced Fatigue gets a multiplicative workload rather than direct stamina edits. Casualty load and a tight
// tether both raise duty, so a heavy snag costs more than a smooth light-casualty drag.
if (!isNil "ace_advanced_fatigue_fnc_addDutyFactor"
    && {!(missionNamespace getVariable ["ACME_dragHandle_dutyRegistered",false])}) then {
    missionNamespace setVariable ["ACME_dragHandle_dutyRegistered",true];
    ["ACME_dragHandle",{
        private _p = ACE_player getVariable ["ACME_dragHandle_patient",objNull];
        if (isNull _p) exitWith {1};
        private _w = ACE_player getVariable ["ACME_dragHandle_weight",350];
        private _t = ACE_player getVariable ["ACME_dragHandle_tension",0];
        (linearConversion [350,950,_w,1.15,1.70,true])
        * (linearConversion [0,1,_t,1,1.35,true])
    }] call ace_advanced_fatigue_fnc_addDutyFactor;
};

if (!hasInterface) exitWith {};

// Patient and self ACE interactions are config-native in CfgVehicles. Keeping them out of postInit avoids
// action-tree timing/inheritance failures and guarantees the patient node is anchored to the pelvis selection.

// Reconcile active pairs from public patient state. This makes the visual naturally JIP-safe.
ACME_dragHandle_visualPairs = createHashMap;
[{
    private _seen = [];
    {
        private _patient = _x;
        if (_patient getVariable ["ACME_dragHandle_active",false]) then {
            private _medic = _patient getVariable ["ACME_dragHandle_dragger",objNull];
            if (!isNull _medic) then {
                private _key = netId _patient;
                _seen pushBack _key;
                ACME_dragHandle_visualPairs set [_key,[_medic,_patient]];
            };
        };
    } forEach allUnits;
    {
        if !(_x in _seen) then {ACME_dragHandle_visualPairs deleteAt _x;};
    } forEach +(keys ACME_dragHandle_visualPairs);
},0.75,[]] call CBA_fnc_addPerFrameHandler;

// Rope/harness visual. A real PhysX rope is intentionally not authoritative here; the patient physics comes only
// from addForce. The drawn loop cannot yank or launch either unit, cannot desync ownership, and follows the
// ragdoll's carry-handle area every render frame.
addMissionEventHandler ["Draw3D",{
    {
        private _pair = ACME_dragHandle_visualPairs get _x;
        _pair params ["_medic","_patient"];
        if (isNull _medic || {isNull _patient}) then {continue};
        if !(_patient getVariable ["ACME_dragHandle_active",false]) then {continue};
        if ((_medic distance cameraOn) > 80 && {(_patient distance cameraOn) > 80}) then {continue};

        private _handleModel = _patient selectionPosition "Spine3";
        if !(_handleModel isEqualType [] && {count _handleModel >= 3} && {vectorMagnitude _handleModel > 0.05}) then {_handleModel=[0,0,0.78];};
        private _handle = _patient modelToWorldVisual _handleModel;
        private _drop = _medic modelToWorldVisual [0,-0.25,0.58];
        private _rear = _medic modelToWorldVisual [0,-0.18,0.93];

        private _slack = missionNamespace getVariable ["ACME_dragHandle_slackLength",1.0];
        private _release = missionNamespace getVariable ["ACME_dragHandle_releaseDistance",2.65];
        private _t = linearConversion [_slack,_release,_drop vectorDistance _handle,0,1,true];
        private _col = [
            0.42 + (0.48 * _t),
            0.34 - (0.18 * _t),
            0.18 - (0.08 * _t),
            0.95
        ];

        // Eight-segment waist loop.
        private _ring = [];
        for "_i" from 0 to 7 do {
            private _a = _i * 45;
            _ring pushBack (_medic modelToWorldVisual [0.25 * sin _a,0.17 * cos _a,0.93]);
        };
        for "_i" from 0 to 7 do {
            drawLine3D [_ring select _i,_ring select ((_i + 1) mod 8),_col];
        };
        drawLine3D [_rear,_drop,_col];
        drawLine3D [_drop,_handle,_col];
    } forEach +(keys ACME_dragHandle_visualPairs);
}];
