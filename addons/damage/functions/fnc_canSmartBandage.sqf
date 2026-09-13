#include "..\script_component.hpp"
params ["_medic", "_patient", "_bodyPart"];
private _result = [_medic, _patient, _bodyPart] call FUNC(getSmartBandagePlan);
private _plan = _result param [0, []];
private _complete = _result param [2, false];
_complete && {(count _plan) > 0}
