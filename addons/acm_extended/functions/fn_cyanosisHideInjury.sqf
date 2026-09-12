// drop ACM's cyanosis row when the saturation does not support it.
// _this is [_ctrl, _target, _selectionN, _entries, _bodyPartName], from ace_medical_gui_updateInjuryListPart.
// _entries is passed by reference, so removing from it removes the rendered row.
// what ACM does: its injury list grades cyanosis with a switch whose last branch is a plain default.
//   severe   if spo2 < severe threshold, or the tourniquet has been on over 120 s
//   moderate if spo2 < moderate threshold, or the tourniquet has been on over 60 s
//   slight   otherwise
// that default is the problem. once the row is pushed at all it is pushed unconditionally, so a casualty sitting
// at 95 percent reads "Slight Cyanosis" on a limb that is not cyanotic. cyanosis is a visible sign and it does not
// appear at 95 percent. it needs roughly 5 g/dl of deoxygenated hemoglobin in the capillary bed, which in a
// casualty with a normal hemoglobin is somewhere in the mid eighties, and lower still if they are anemic, which
// is exactly why a bled-out casualty can be profoundly hypoxic and never look blue at all.
// so the row is removed above the threshold rather than reworded. a sign that is not there should not be reported.
// a tourniqueted limb is left alone. that limb genuinely is dusky, whatever the pulse oximeter on the other arm
// says, because it is not being perfused. ACM already grades that case by tourniquet time and it is correct.
// the threshold is a setting, ACME_cyanosis_spo2Floor, so a unit that wants ACM's original behavior can set it
// to 100 and get every row back.
params ["", "_target", "_selectionN", "_entries", ""];
if (isNil "_entries") exitWith {};
if (isNull _target) exitWith {};

private _floor = missionNamespace getVariable ["ACME_cyanosis_spo2Floor", 90];
if (_floor >= 100) exitWith {};  // the suppression is off: leave ACM's rows exactly as they were.

// it is ace_medical_spo2. ace_medical_oxygenSaturation does not exist, so this returned the default 100 for every
// casualty and the filter suppressed the cyanosis row on all of them at every saturation. cyanosis simply never
// appeared. it is the third time this session that a wrong ACE variable name has silently returned a default and
// disabled the thing that read it.
private _spo2 = _target getVariable ["ace_medical_spo2", 100];
if (_spo2 < _floor) exitWith {};  // genuinely hypoxic, so the sign is real and the row stands.

// a tourniqueted limb is dusky regardless of the central saturation, so leave those rows alone.
private _tqs = _target getVariable ["ace_medical_tourniquets", [0,0,0,0,0,0]];
if ((_tqs param [_selectionN, 0]) > 0) exitWith {};

// ACM colors the cyanosis row [0.16, scale, 1, 1]. the scale varies with severity and tourniquet time, so match
// on the three fixed channels and ignore the second, the same way fn_aajttqhideinjury matches the tourniquet amber.
for "_i" from ((count _entries) - 1) to 0 step -1 do {
    private _c = (_entries select _i) param [1, []];
    if ((count _c) >= 4
        && {abs ((_c select 0) - 0.16) < 0.001}
        && {abs ((_c select 2) - 1) < 0.001}
        && {abs ((_c select 3) - 1) < 0.001}) then {
        _entries deleteAt _i;
    };
};
