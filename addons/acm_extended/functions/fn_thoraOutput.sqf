// what the chest tube has put out, and what that means.
// call it as [_patient, _drainedLiters] call ACME_fnc_thoraOutput from the drain loop each time fluid leaves.
//
// the chest tube is the only instrument in trauma that hands the provider a number. how much came out when it
// went in, and how fast it keeps coming, is the decision. it is not a physiology model, it is a threshold the
// medic is meant to read and act on.
// two figures matter, and both are the real ones.
//   1500 ml on insertion, or shortly after, means the bleeding is surgical and no field care will stop it.
//   200 ml per hour, sustained, means the same thing arrived at slowly.
// either one flags the casualty. nothing in the rest of this addon tells a provider "this is past you, move now"
// with a number attached, which is the whole reason this exists.
// the two figures are measured from two different things, and that distinction is the whole model.
// _drained is what left the chest this tick. it feeds the running total, because the total is simply how much
// blood has come out of this casualty.
// _newBleed is how much fresh blood arrived in the chest this tick, which is what the hourly rate is measured
// from. the rate is meant to say how fast they are still bleeding, not how fast the tube empties a pool that was
// already there. measured off the drain instead, the tube runs at 7200 ml per hour and every casualty crosses a
// 200 ml per hour threshold within a second of insertion, which would make the number meaningless.
params ["_patient", ["_drained", 0], ["_newBleed", 0], ["_sampleAt", CBA_missionTime]];
if (isNull _patient) exitWith {};
// Stable accounting authority: the history does not disappear when the patient changes owner.
if (!isServer) exitWith { ["ACME_thoraOutput", [_patient, _drained, _newBleed, _sampleAt]] call CBA_fnc_serverEvent; };
if (_sampleAt <= (_patient getVariable ["ACME_NA2_resetServerTime", -1])) exitWith {};
if (_drained <= 0 && {_newBleed <= 0}) exitWith {};

private _ml = _drained * 1000;
private _total = (_patient getVariable ["ACME_thora_outputMl", 0]) + _ml;
[_patient, "ml", _total, true] call ACME_fnc_thoraOutputStateCommit;

// the hourly rate, measured over a rolling window rather than since insertion. a casualty who put out a liter an
// hour ago and has been dry since is not still bleeding, and a rate taken from the total would say they were.
private _now = CBA_missionTime;
private _win = missionNamespace getVariable ["ACME_thora_rateWindowSec", 600];
private _hist = _patient getVariable ["ACME_thora_outputHist", []];
if !(_hist isEqualType []) then { _hist = [] };
if (_newBleed > 0) then { _hist pushBack [_now, _newBleed * 1000]; };
_hist = _hist select { (_now - (_x select 0)) <= _win };
[_patient, "hist", _hist, false] call ACME_fnc_thoraOutputStateCommit;

private _inWindow = 0;
{ _inWindow = _inWindow + (_x select 1); } forEach _hist;
private _span = _win min (_now - (_patient getVariable ["ACME_thora_outputStart", _now]));
if (_span < 60) then { _span = 60 };
private _perHour = _inWindow * (3600 / _span);
[_patient, "perHour", _perHour, true] call ACME_fnc_thoraOutputStateCommit;

// no threshold flagging here. a casualty is not surgical because of how much came out of the tube. they are
// surgical because a provider had to put bilateral tubes in them, which is decided in fn_thoraMouseDown at the
// moment the second tube goes in.
// this function only counts. the figure is shown on the torso so the provider can see the trend, and it carries
// no consequence of its own.
