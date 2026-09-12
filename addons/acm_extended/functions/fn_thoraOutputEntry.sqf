// add the chest tube output to the medical menu injury list for the torso.
// it hooks ACM's own pre-render event, ace_medical_gui_updateInjuryListWounds, which passes the entries array by
// reference, so pushing onto it adds a rendered row with no override needed.
// _this is [_ctrl, _target, _selectionN, _woundEntries, _bodyPartName].
//
// the number is the point. a chest tube is the only thing in trauma that tells the provider how much is coming
// out and how fast, and those two figures are what decide whether this casualty can be managed here or needs a
// surgeon. showing them in the log alone would hide them behind a scroll.
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN != 1}) exitWith {};  // torso only.

private _total = _target getVariable ["ACME_thora_outputMl", 0];
if (_total <= 0) exitWith {};

private _perHour = _target getVariable ["ACME_thora_outputPerHour", 0];
// bilateral tubes, which is what actually makes this casualty surgical. the output figure is information and
// carries no verdict of its own.
private _bilateral = (_target getVariable ["ACME_thora_tube_left", false])
    && {_target getVariable ["ACME_thora_tube_right", false]};

// white while the numbers are unremarkable, amber once the casualty is bleeding back into the chest faster than
// a provider would want to see. it is a trend indicator, not a verdict.
// the point at which the output figure turns amber. it is a trend cue for the provider and nothing more.
private _hourly = missionNamespace getVariable ["ACME_thora_amberPerHourMl", 200];
private _col = if (_perHour >= _hourly) then { [0.95, 0.70, 0.20, 1] } else { [1, 1, 1, 1] };

private _txt = if (_perHour >= 1) then {
    format ["Chest tube output: %1 ml (%2 ml/hr)", round _total, round _perHour]
} else {
    format ["Chest tube output: %1 ml", round _total]
};
_woundEntries pushBack [_txt, _col];

if (_bilateral) then {
    _woundEntries pushBack ["Bilateral chest tubes. Surgical casualty", [0.85, 0.15, 0.15, 1]];
};
