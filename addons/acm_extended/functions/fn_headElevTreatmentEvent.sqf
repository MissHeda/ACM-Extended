/* Owner-side suspension leases for concurrent providers. Local treatment IDs pair start/end. */
params ["_patient", "_medic", "_id", "_start", "_token"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevTreatment", _this] call ACME_fnc_ownerDispatch;};
if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _token) exitWith {};
private _leases = _patient getVariable ["ACME_headElev_treatments", createHashMap];
if (_start) then {
    if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};
    _leases set [_id, [_medic, CBA_missionTime]];
    _patient setVariable ["ACME_headElev_treatments", _leases, true];
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
    [_patient] call ACME_fnc_headElevSuspend;
} else {
    _leases deleteAt _id;
    _patient setVariable ["ACME_headElev_treatments", _leases, true];
    if (_patient getVariable ["ACME_headElev_Suspended", false]) then {
        _patient setVariable ["ACME_headElev_ResumePending", true, true];
        [{_this call ACME_fnc_headElevTryResume;}, [_patient, _token], 0.75] call CBA_fnc_waitAndExecute;
    };
};
