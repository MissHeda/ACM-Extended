// airway grades: how hard is this person to intubate.
// call it as [_patient] call ACME_fnc_airwayGrade, which returns [mallampati, cormacklehane], each 1 to 4.
// Cached grades can worsen with new injury, not merely from a miss. Full heal clears injury-related grading.
// there are three inputs, in the order they matter.
// 1. who they are. mallampati is anatomy, so it is bound to the player the way ACM binds blood type: two digits of
// the UID give a stable number, and the same person is the same airway in every mission forever. a medic who has
// intubated someone once knows what they are getting next time, which is the point.
// it uses different digits from the blood type. ACM reads [15,2] and this reads [11,2]. sharing the offset would
// make every o-negative in the unit permanently a mallampati iii, and the correlation would be visible within a
// week.
// 2. what they weigh. a higher mass crowds the airway: more soft tissue in the pharynx, a shorter thicker neck and
// a bulkier tongue base. it is a real and well known predictor, so weight shifts the roll upward rather than
// selecting a grade outright. anatomy still leads.
// 3. what happened to them. grade 4 is not something a person simply has. it is earned by trauma: facial
// fractures, burns, swelling and blood. below the damage threshold grade 4 cannot occur at all, so when a medic
// meets one they know why, and it is never bad luck.
// cormack-lehane is conditioned on mallampati rather than rolled independently. a high mallampati genuinely
// predicts a hard view, imperfectly. rolling them separately would throw that relationship away and make the
// pre-check meaningless. so a hard airway usually gives a hard view, sometimes does not, and an easy one
// occasionally surprises you. that is why you assess and then still look.

params ["_patient"];

if (isNull _patient) exitWith { [1, 1] };

// 5. trauma, the only route to grade 4. it needs head damage plus anything actively fouling the airway. both
// scales move together, because the same swelling that hides the landmarks is what crowds the mouth.
// ace_medical_fnc_getBodyPartDamage does not exist. it never has, in any ACE version, so this threw an undefined
// variable every time an airway was graded, which is every intubation attempt.
// ACE keeps the damage as a plain array on the unit, and the head is index 0, per HITPOINT_INDEX_HEAD in
// medical_engine\script_macros_medical.hpp. read it directly.
private _bpd = _patient getVariable ["ace_medical_bodyPartDamage", [0,0,0,0,0,0]];
private _head = _bpd param [0, 0];
private _foul = 0;
// ACM airway/fnc_getAirwayState.sqf reads these native obstruction and collapse states.
private _occluded = ((_patient getVariable ["ACM_airway_AirwayCollapse_State", 0]) > 0)
    || {(_patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0]) > 0};
if (_occluded) then { _foul = _foul + 0.20; };
if ((_patient getVariable ["ACM_airway_AirwayObstructionBlood_State", 0]) > 0) then { _foul = _foul + 0.20; };
if ([_patient] call ACME_fnc_airwayHasFacialBurn) then { _foul = _foul + 0.25; };

private _insult = _head + _foul;
private _bump = switch (true) do {
    case (_insult >= (missionNamespace getVariable ["ACME_airway_grade4Threshold", 0.75])): { 2 };
    case (_insult >= (missionNamespace getVariable ["ACME_airway_grade3Threshold", 0.45])): { 1 };
    default { 0 };
};

// Keep the worst graded view until full heal. Apply only newly increased trauma once.
// B12 misses do not raise cached grades or remove the ability to intubate.
private _cached = _patient getVariable ["ACME_airwayGrade", []];
if (_cached isEqualType [] && {count _cached == 2}) exitWith {
    private _previous = _patient getVariable ["ACME_airwayTraumaBump", _bump];
    private _increase = (_bump - _previous) max 0;
    if (_increase > 0) then {
        _cached = [((_cached select 0) + _increase) min 4, ((_cached select 1) + _increase) min 4];
        _patient setVariable ["ACME_airwayGrade", _cached, true];
    };
    if (isNil {_patient getVariable "ACME_airwayTraumaBump"} || {_increase > 0}) then {
        _patient setVariable ["ACME_airwayTraumaBump", _bump max _previous, true];
    };
    _cached
};

// 1. the roll. there are two independent draws, so mallampati and the cormack-lehane variation are not locked
// together.
private _rMP = floor (random 100);
private _rCL = floor (random 100);
if (isPlayer _patient && {isMultiplayer}) then {
    private _uid = getPlayerUID _patient;
    if (count _uid > 14) then {
        _rMP = parseNumber (_uid select [11, 2]);
        _rCL = parseNumber (_uid select [13, 2]);
    };
};

// 2. weight. it nudges the roll rather than choosing for it. a heavy casualty is more likely to be a difficult
// airway and is not guaranteed to be one, which is true and also stops weight becoming a label.
private _kg = _patient getVariable ["ACE_medical_weight", 80];
private _wShift = linearConversion [70, 130, _kg, 0, 22, true];
_rMP = (_rMP + _wShift) min 99;
_rCL = (_rCL + (_wShift * 0.6)) min 99;

// 3. the baseline mallampati, roughly the real world spread. grade 4 is deliberately unreachable here.
private _mp = switch (true) do {
    case (_rMP < 40): { 1 };
    case (_rMP < 85): { 2 };
    default          { 3 };
};

// 4. cormack-lehane, given the mallampati.
private _clTable = switch (_mp) do {
    case 1:  { [85, 100] };  // 85 percent cl1, 15 percent cl2.
    case 2:  { [60,  95] };  // 60 percent cl1, 35 percent cl2, 5 percent cl3.
    default  { [25,  75] };  // 25 percent cl1, 50 percent cl2, 25 percent cl3.
};
private _cl = switch (true) do {
    case (_rCL < (_clTable select 0)): { 1 };
    case (_rCL < (_clTable select 1)): { 2 };
    default                            { 3 };
};

_mp = (_mp + _bump) min 4;
_cl = (_cl + _bump) min 4;

// Preserve the established grade until a new injury or full heal changes it.
private _out = [_mp, _cl];
_patient setVariable ["ACME_airwayGrade", _out, true];
_patient setVariable ["ACME_airwayTraumaBump", _bump, true];
_out
