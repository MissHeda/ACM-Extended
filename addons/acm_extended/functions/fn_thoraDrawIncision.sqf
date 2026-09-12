// render an incision as a row of small dark-red segment dots along a locked axis.
// it works in body-fraction, uv, space so it follows the stretched body image feature, and each dot is converted
// back to ui. it is isolated here so the render can later be swapped for a drawicon wound texture without touching
// the mechanic.
// call it as [_startUV, _angleDeg, _lengthUV] call ACME_fnc_thoraDrawIncision, where a _lengthUV of 0 or below hides
// it.
params ["_startUV", "_angleDeg", "_lengthUV"];
disableSerialization;
private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
private _segs = uiNamespace getVariable ["ACME_Thora_IncSegs", []];
if (count _rect != 4 || {_segs isEqualTo []}) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];
_startUV params ["_su", "_sv"];

private _n = count _segs;
private _stepUV = 0.007;
private _count = if (_lengthUV > 0.001) then { ((round (_lengthUV / _stepUV)) + 1) min _n max 1 } else { 0 };
private _dirU = cos _angleDeg;
private _dirV = sin _angleDeg;
private _thick = _bh * 0.016;
{
    if (_forEachIndex >= _count) then {
        _x ctrlShow false;
    } else {
        private _t = (_stepUV * _forEachIndex) min _lengthUV;
        private _pu = _su + (_dirU * _t);
        private _pv = _sv + (_dirV * _t);
        _x ctrlSetPosition [(_bx + (_pu * _bw)) - (_thick / 2), (_by + (_pv * _bh)) - (_thick / 2), _thick, _thick];
        _x ctrlSetTextColor [0.55, 0.05, 0.05, 0.95];
        _x ctrlShow true;
        _x ctrlCommit 0;
    };
} forEach _segs;
