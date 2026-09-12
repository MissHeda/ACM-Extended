/* Provider-owned continuous support uses ACM's BVM-style action lifecycle.
   The patient owner reserves the token before this request. */
params ["_medic", "_patient", "_bodyPart", "_token", ["_ready", false]];
if (!local _medic) exitWith {[_medic, "headElevHoldStart", _this] call ACME_fnc_ownerDispatch;};
private _release = {
    [_patient, "headElevHoldRelease", [_medic, _patient, _token]] call ACME_fnc_ownerDispatch;
};
if (!hasInterface || {!isPlayer _medic} || {_medic != ACE_player} || {!alive _medic} || {isNull _patient}
    || {!alive _patient} || {_medic getVariable ["ACE_isUnconscious", false]}
    || {missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]}) exitWith {call _release;};
if (!_ready) exitWith {
    // Let the preceding treatment finish and close its own progress display first.
    ace_medical_gui_pendingReopen = false;
    private _menu = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
    if (!isNull _menu) then {_menu closeDisplay 1;};
    [{
        params ["_medic", "_patient", "_bodyPart", "_token"];
        !dialog && {(_patient getVariable ["ACME_headElev_poseToken", ""]) == _token}
    }, {
        (_this + [true]) call ACME_fnc_headElevHoldStart;
    }, [_medic, _patient, _bodyPart, _token], 3, {
        params ["_medic", "_patient", "_bodyPart", "_token"];
        [_patient, "headElevHoldRelease", [_medic, _patient, _token]] call ACME_fnc_ownerDispatch;
    }] call CBA_fnc_waitUntilAndExecute;
};
if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _token
    || {!(_patient getVariable ["ACME_headElevated", false])}) exitWith {call _release;};
[_medic] call ACME_fnc_medicAnimationPrep;
_medic setUnitPos "MIDDLE";
[[ _medic, _patient, _bodyPart, [_token] ], {
    params ["_medic", "_patient", "_bodyPart", "_extra"];
    _medic setVariable ["ACME_headElev_holding", [_patient, _extra select 0], true];
}, {
    params ["_medic", "_patient", "_bodyPart", "_extra"];
    private _token = _extra select 0;
    if ((_medic getVariable ["ACME_headElev_holding", []]) isEqualTo [_patient, _token]) then {
        _medic setVariable ["ACME_headElev_holding", [], true];
    };
    [_patient, "headElevHoldRelease", [_medic, _patient, _token]] call ACME_fnc_ownerDispatch;
}, {
    params ["_medic", "_patient", "_bodyPart", "_extra"];
    private _token = _extra select 0;
    private _hold = _patient getVariable ["ACME_headElev_hold", []];
    if (!alive _patient || {!(_patient getVariable ["ACME_headElevated", false])}
        || {(_patient getVariable ["ACME_headElev_poseToken", ""]) != _token}
        || {(_hold param [0, objNull]) != _medic}
        || {_patient getVariable ["ACME_headElev_Suspended", false]}) then {
        ACM_core_ContinuousAction_Active = false;
    };
}, false] call ACM_core_fnc_beginContinuousAction;
