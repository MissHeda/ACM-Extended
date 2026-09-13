#include "..\script_component.hpp"
params ["_medic", "_patient", "_bodyPart"];
private _result = [_medic, _patient, _bodyPart] call FUNC(getSmartBandagePlan);
private _plan = _result param [0, []];
if (_plan isEqualTo [] || {!(_result param [2, false])}) exitWith {0};
(_result param [1, 0]) max 2.25
