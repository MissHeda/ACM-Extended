/* Time-based two-axis filter. UI and hit testing must use this same returned offset.
   This function has no stored state, network work, controls, or frame generation. */
params [["_target", [0,0], [[]], 2], ["_previous", [0,0], [[]], 2],
    ["_dt", 0, [0]], ["_tau", 0.12, [0]]];
_target = _target apply {if (_x isEqualType 0 && {finite _x}) then {_x} else {0}};
_previous = _previous apply {if (_x isEqualType 0 && {finite _x}) then {_x} else {0}};
if (!finite _dt || {_dt < 0}) then {_dt = 0;};
if (!finite _tau) then {_tau = 0.12;};
_tau = _tau max 0.02 min 0.4;
// Limit the step after a stall. Reopening after a longer gap resets at the caller.
private _a = 1 - exp (-((_dt min 0.1) / _tau));
[(_previous select 0) + ((_target select 0) - (_previous select 0)) * _a,
 (_previous select 1) + ((_target select 1) - (_previous select 1)) * _a]
