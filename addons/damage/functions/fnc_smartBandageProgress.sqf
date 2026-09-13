#include "..\script_component.hpp"
params ["_args"];
_args params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {false};
private _txn = _medic getVariable [QGVAR(smartBandageTxn), []];
!(_txn isEqualTo []) && {(_txn param [0, objNull]) isEqualTo _patient} && {(_txn param [1, ""]) == toLowerANSI _bodyPart}
