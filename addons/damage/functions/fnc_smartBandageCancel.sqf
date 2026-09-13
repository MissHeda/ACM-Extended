#include "..\script_component.hpp"
params ["_medic"];
if (isNull _medic) exitWith {};
private _txn = _medic getVariable [QGVAR(smartBandageTxn), []];
[_medic, _txn] call FUNC(smartBandageRestore);
