params [["_dropsPerMinute", 60]];

private _maxDrops = missionNamespace getVariable ["ACME_infusion_maxDropsPerMinute", 120];
private _curve = missionNamespace getVariable ["ACME_infusion_clampCurve", 2];

if (_dropsPerMinute <= 0 || {_maxDrops <= 0}) exitWith {0};
((_dropsPerMinute / _maxDrops) max 0 min 1) ^ (1 / (_curve max 0.01));
