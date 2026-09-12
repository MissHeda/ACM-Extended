params ["_patient", "_bagUid"];
if (!local _patient) exitWith {};
private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _keep = [];
{
    if ((_x param [23, ""]) == _bagUid) then {
        [_patient, _x, true] call ACME_fnc_infusionDeliver;
        private _part = ACME_infusion_bodyParts find toLowerANSI (_x select 1);
        _patient setVariable [format ["ACME_clampRate_%1_%2_%3", _part, _x select 5, _x select 4], -1, false];
    } else {_keep pushBack _x;};
} forEach _entries;
[_patient, _keep] call ACME_fnc_infusionMedicationStateCommit;
