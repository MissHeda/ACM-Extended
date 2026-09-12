// Server-issued wound identity survives regrouping and distinguishes identical puncture coordinates.
// UI rows hold local controls at 6/7 and the stable ID at 8; the network envelope uses 0/0 instead.
params ["_hole"];
if !(_hole isEqualType [] && {count _hole >= 6}) exitWith {[]};
private _id = _hole param [8, ""];
if (_id isEqualType "" && {_id != ""}) exitWith {[_id]};
// Legacy six-column records are accepted only for migration/identity matching.
[_hole select 0, _hole select 1, _hole select 2, _hole select 5]
