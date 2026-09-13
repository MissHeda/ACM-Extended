#include "..\script_component.hpp"
/* Reserve the entire computed bundle up front so inventory races cannot make a long treatment partially free. */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {};
private _old = _medic getVariable [QGVAR(smartBandageTxn), []];
if (_old isNotEqualTo []) then {[_medic, _old] call FUNC(smartBandageRestore);};
private _result = [_medic, _patient, _bodyPart] call FUNC(getSmartBandagePlan);
private _plan = _result param [0, []];
if (_plan isEqualTo [] || {!(_result param [2, false])}) exitWith {};
private _reserved = [];
private _ok = true;
{
    _x params ["", "_item"];
    private _owner = objNull;
    if (([_medic, _item] call ace_common_fnc_getCountOfItem) > 0) then {_owner = _medic;} else {
        if (_patient != _medic && {([_patient, _item] call ace_common_fnc_getCountOfItem) > 0}) then {_owner = _patient;};
    };
    if (isNull _owner || {!([_owner, _item] call ace_common_fnc_useItem)}) exitWith {_ok = false;};
    _reserved pushBack [_owner, _item];
} forEach _plan;
if (!_ok) exitWith {
    [_medic, [_patient, toLowerANSI _bodyPart, _plan, _reserved]] call FUNC(smartBandageRestore);
};
_medic setVariable [QGVAR(smartBandageTxn), [_patient, toLowerANSI _bodyPart, _plan, _reserved], false];
