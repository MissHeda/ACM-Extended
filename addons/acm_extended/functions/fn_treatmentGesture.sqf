/* B52 one-shot provider gesture for instantaneous minigame actions.
 * Never interrupts another ACME-owned finite treatment pose. Never replays while already active.
 * _duration is the maximum owned window; <=0 lets the helper use a safe native-duration fallback.
 */
params [
    ["_medic", objNull, [objNull]],
    ["_mode", "", [""]],
    ["_duration", -1, [0]]
];
if (isNull _medic || {!local _medic} || {!alive _medic} || {_mode == ""}) exitWith {false};
private _existing = _medic getVariable ["ACME_treatmentPoseState", []];
if !(_existing isEqualTo []) exitWith {false};
private _window = if (_duration > 0) then {_duration} else {3};
// B54: the controller crouches a standing or prone provider first, so the gesture window starts after that
// BI transition rather than being eaten by it.
private _entry = switch (stance _medic) do {case "STAND": {0.65}; case "PRONE": {1.116}; default {0};};
private _epoch = [_medic, _mode, _window] call ACME_fnc_treatmentPoseStart;
if !(_epoch isEqualType 0) exitWith {false};
[{params ["_m","_mode","_epoch"]; if (!isNull _m) then {[_m,_mode,_epoch] call ACME_fnc_treatmentPoseStop;};}, [_medic,_mode,_epoch], _window + _entry] call CBA_fnc_waitAndExecute;
true
