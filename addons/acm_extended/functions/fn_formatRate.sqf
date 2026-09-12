params ["_doseRemaining", "_remainingVolume", "_dropSet", "_dropsPerMinute", ["_clampPosition", -1]];

private _mlPerMinute = if (_dropSet > 0) then {_dropsPerMinute / _dropSet} else {0};
private _minutesLeft = if (_mlPerMinute > 0) then {(_remainingVolume max 0) / _mlPerMinute} else {0};
private _rateText = if (_dropsPerMinute < 10) then {_dropsPerMinute toFixed 1} else {str (round _dropsPerMinute)};
private _timeText = if (_mlPerMinute <= 0) then {"stopped"} else {if (_minutesLeft >= 60) then {format ["~%1 hr", (_minutesLeft / 60) toFixed 1]} else {format ["~%1 min", round _minutesLeft]}};
private _mlText = if (_mlPerMinute < 10) then {_mlPerMinute toFixed 1} else {str (round _mlPerMinute)};
private _clampText = "";

// the drug delivery rate. for a premixed drug bag the drug and the volume deplete together, so the live
// concentration is simply the dose remaining over the volume remaining, in mg/ml, and times the flow that gives
// mg/min. plain fluids carry no dose, so the field is omitted for them.
private _mgText = "";
if (_doseRemaining > 0 && {_remainingVolume > 0}) then {
    private _conc = _doseRemaining / _remainingVolume;  // mg/ml
    private _mgPerMinute = _mlPerMinute * _conc;
    private _mgStr = if (_mgPerMinute < 1) then {_mgPerMinute toFixed 2} else {_mgPerMinute toFixed 1};
    _mgText = format [" | %1 mg/min", _mgStr];
};

if (_clampPosition >= 0) then {
    _clampText = format [" | %1%% open", round (((_clampPosition max 0) min 1) * 100)];
};

format ["%1 gtt/mL | %2 gtt/min | %3 mL/min%6 | %4%5", round _dropSet, _rateText, _mlText, _timeText, _clampText, _mgText]
