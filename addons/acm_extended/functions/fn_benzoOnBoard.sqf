// the effective benzodiazepine administrations on board, summed across the classnames a benzo can be recorded
// under.
// the narc box, in fn_skinjectsite, records an iv push as "<drug>_IV" and an im push as "<drug>", so both spellings
// must be summed or an iv midazolam, the usual seizure route, is missed entirely and the benzo never registers.
// getMedicationCount returns [cumulativedose, effectivecount], where the effective count is about 1 per fresh
// administration and decays as it ages out of the system. older ACE returned a bare number, so handle both
// shapes.
// call it as [_patient] call ACME_fnc_benzoOnBoard, which returns a number, the effective benzo administrations on
// board.
params ["_patient"];
if (isNull _patient || {isNil "ace_medical_status_fnc_getMedicationCount"}) exitWith {0};

private _names = missionNamespace getVariable ["ACME_lido_benzoClassnames", ["Midazolam", "Midazolam_IV"]];
private _total = 0;
{
    private _r = [_patient, _x, false] call ace_medical_status_fnc_getMedicationCount;
    _total = _total + (if (_r isEqualType []) then { _r param [1, 0] } else { _r });
} forEach _names;
_total
