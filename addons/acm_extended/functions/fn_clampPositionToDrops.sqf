params [["_position", 0.5]];

_position = (_position max 0) min 1;
if (_position <= 0.01) exitWith {0};

private _curve = missionNamespace getVariable ["ACME_infusion_clampCurve", 2];
private _maxDrops = missionNamespace getVariable ["ACME_infusion_maxDropsPerMinute", 120];
private _drops = _maxDrops * (_position ^ _curve);

(round (_drops / 5)) * 5;
