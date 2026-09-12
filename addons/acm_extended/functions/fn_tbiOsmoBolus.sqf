// the osmotherapy push-bolus callback. it is used by the HTS 23.4 percent, 30 ml, bullet and the mannitol push
// treatment actions. it is a single dose with verbose feedback, and it consumes the item.
// the 23.4 percent bolus is the herniation rescue, where a central line is preferred: it buys minutes of ICP
// reduction, and it does not fix the lesion.
// _this is the ACE callback [_medic, _patient, _bodyPart] plus a bound [_agent, _dose, _item].
params ["_medic", "_patient", "_bodyPart", "_args"];
if !([_medic, "htsBolus"] call ACME_fnc_procedureAllowed) exitWith {};
_args params [["_agent", "Mannitol"], ["_dose", 100], ["_item", ""]];
if (isNull _patient) exitWith {};
// The action does not reserve an item before progress. Debit once, after the live
// permission check, and honor ACE shared equipment. Failed/disabled actions spend
// nothing; the former progress debit plus manual remove consumed two bullets.
if (_item != "") then {
    private _used = [_medic, _patient, [_item]] call ace_medical_treatment_fnc_useItem;
    if ((_used param [1, ""]) != _item) then {_item = "__UNAVAILABLE__";};
};
if (_item == "__UNAVAILABLE__") exitWith {};

// there is no TBI state, so there is nothing to act on, and it still consumes realistically.
private _state = _patient getVariable ["ACME_tbi_State", createHashMap];
if (count _state == 0) then {
    [format ["%1 given - no measurable ICP effect (no TBI state on patient).", _agent], 2, _medic] call ace_common_fnc_displayTextStructured;
} else {
    [_patient, _agent, _dose, false] call ACME_fnc_tbiApplyOsmotherapy;
};
