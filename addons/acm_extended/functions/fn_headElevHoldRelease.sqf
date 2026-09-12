/* A late provider callback cannot lower a later support episode. */
params ["_medic", "_patient", "_token"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevHoldRelease", _this] call ACME_fnc_ownerDispatch;};
private _hold = _patient getVariable ["ACME_headElev_hold", []];
if ((_hold param [0, objNull]) != _medic || {(_hold param [1, ""]) != _token}
    || {(_patient getVariable ["ACME_headElev_poseToken", ""]) != _token}) exitWith {};
// The native continuous action releases the medic; do not start another medic animation.
[objNull, _patient] call ACME_fnc_headElevateStop;
