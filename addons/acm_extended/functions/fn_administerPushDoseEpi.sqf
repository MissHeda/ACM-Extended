/* Compatibility action: give a measured 1 mL / 10 mcg from a B12 syringe, no legacy abstract charge tokens. New preparation never creates unmeasured charge tokens. */
params ["_medic", "_patient", "_bodyPart"];
if !([_medic, "pushDoseEpi"] call ACME_fnc_procedureAllowed) exitWith {};
if (isNull _patient || {!local _medic} || {!alive _patient}) exitWith {};
if (!([_patient, _bodyPart, 0] call ACM_circulation_fnc_hasIV) && {!([_patient, _bodyPart, 0] call ACM_circulation_fnc_hasIO)}) exitWith {
    ["An IV/IO at the selected site is required.", 3, _medic] call ace_common_fnc_displayTextStructured;
};
private _store = _medic getVariable ["ACME_narcStore", []];
private _index = _store findIf {(_x param [6, ""]) == "epiMixB12" && {(_x param [2, 0]) + (_x param [4, 0]) >= 0.9999}};
if (_index >= 0) exitWith {[_medic, _patient, _bodyPart, _index, 1] call ACME_fnc_epinephrinePushStored;};
["Prepare epinephrine 10 mcg/mL from the dedicated 1:10,000 source first. Legacy charge tokens are not medication.", 4, _medic] call ace_common_fnc_displayTextStructured;
