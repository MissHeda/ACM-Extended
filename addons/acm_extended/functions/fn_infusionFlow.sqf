params ["_patient", "_entry"];
private _part = ACME_infusion_bodyParts find toLowerANSI (_entry param [1, ""]);
private _site = _entry param [4, -1]; private _iv = _entry param [5, true];
// Native IO uses site -1; it still has a real roller clamp.
if (_part < 0 || {_iv && {_site < 0}}) exitWith {0};
private _clamp = _entry param [22, -1];
private _drops = _entry param [21, 60];
if (_clamp >= 0) then {_drops = [(_clamp max 0) min 1] call ACME_fnc_clampPositionToDrops;};
private _rate = (_drops / ((_entry param [20, 20]) max 1)) / 60;
_patient setVariable [format ["ACME_clampRate_%1_%2_%3", _part, _iv, _site], _rate max 0, false];

// Explicit return for the authoritative per-bag drainer; the legacy site cache
// remains available to displays/older callers but is no longer shared flow authority.
_rate max 0
