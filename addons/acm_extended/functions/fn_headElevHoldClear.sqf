/* Patient-owned cleanup. A clear never cancels an unrelated provider action. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
private _hold = _patient getVariable ["ACME_headElev_hold", []];
if (_hold isEqualTo []) exitWith {};
_hold params ["_medic", "_token"];
_patient setVariable ["ACME_headElev_hold", [], true];
if (!isNull _medic) then {
    [_medic, "headElevHoldStop", [_medic, _patient, _token]] call ACME_fnc_ownerDispatch;
};
