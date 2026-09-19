// Patient-owner authoritative teardown.
params [["_patient",objNull,[objNull]],["_medic",objNull,[objNull]],["_reason","manual",[""]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient,"dragHandleStop",[_patient,_medic,_reason]] call ACME_fnc_ownerDispatch;};

private _activeMedic = _patient getVariable ["ACME_dragHandle_dragger",objNull];
if (isNull _medic) then {_medic = _activeMedic;};
if (!isNull _activeMedic && {!isNull _medic} && {_activeMedic isNotEqualTo _medic}) exitWith {};

private _session = _patient getVariable ["ACME_dragHandle_session",""];

private _pfh = _patient getVariable ["ACME_dragHandle_forcePFH",-1];
if (_pfh isEqualType 0 && {_pfh >= 0}) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
_patient setVariable ["ACME_dragHandle_forcePFH",-1];

private _oldFlags = _patient getVariable ["ACME_dragHandle_oldAceFlags",[true,true]];
_patient setVariable ["ace_dragging_canDrag",_oldFlags param [0,true],true];
_patient setVariable ["ace_dragging_canCarry",_oldFlags param [1,true],true];

_patient setVariable ["ACME_dragHandle_active",false,true];
_patient setVariable ["ACME_dragHandle_dragger",objNull,true];
_patient setVariable ["ACME_dragHandle_weight",nil,true];
_patient setVariable ["ACME_dragHandle_session","",true];
_patient setVariable ["ACME_dragHandle_tension",nil];
_patient setVariable ["ACME_dragHandle_oldAceFlags",nil,true];

// Restore passive head elevation after the casualty has been put back down. A casualty loaded into a vehicle
// intentionally loses the pending elevation, matching ACE carry-to-cargo semantics. If a pose-owning procedure
// forced the release, wait until that procedure gives the patient animation lease back before trying to re-elevate.
if (_reason == "patient_vehicle") then {
    _patient setVariable ["ACME_headElev_TransportPending",nil,true];
} else {
if (_reason == "procedure" && {_patient getVariable ["ACME_headElev_TransportPending",false]}) then {
    [
        {
            params ["_p"];
            if (isNull _p || {!alive _p}) exitWith {true};
            private _lock = _p getVariable ["ACME_patientAnimLock",[]];
            !((count _lock) >= 5 && {(_lock param [4,-1]) > CBA_missionTime})
        },
        {
            params ["_p"];
            if (!isNull _p && {alive _p}) then {
                if (local _p) then {
                    ["ACME_headElev_transportUp",[_p]] call CBA_fnc_localEvent;
                } else {
                    ["ACME_headElev_transportUp",[_p],_p] call CBA_fnc_targetEvent;
                };
            };
        },
        [_patient]
    ] call CBA_fnc_waitUntilAndExecute;
} else {
    ["ACME_headElev_transportUp",[_patient]] call CBA_fnc_localEvent;
};
};

if (!isNull _medic) then {
    ["ACME_dragHandle_stopped",[_medic,_patient,_reason,_session],_medic] call CBA_fnc_targetEvent;
};
