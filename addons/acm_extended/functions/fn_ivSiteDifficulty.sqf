// compute how hard a peripheral iv stick should be for this patient, limb and needle gauge, mirroring how ACM
// itself decides whether a peripheral vein takes a stick. ACM's fnc_setiv, in the conscious and perfusing case,
// scales success purely off the systolic pressure.
// arms use linearconversion [70, 90, systolic, 0, 1], so it is impossible at or below 70 and certain at or above
// 90.
// legs use linearconversion [60, 80, systolic, 0, 1], so it is impossible at or below 60 and certain at or above
// 80.
// below those windows the vein is functionally flat, and ACM would almost always fail the stick. we translate that
// same patency into mini-game difficulty, so the feel and the stick match the physiology.
// a well-perfused patient is easy to feel, because the dot reaches green, with a forgiving stick radius.
// a patient at or below ACM's fail threshold is barely palpable, because the dot barely warms and never goes fully
// green, with a pinpoint stick.
// the needle gauge scales the precision required: a bigger bore, 14g, needs a tighter, more skilled stick than a
// small one, 18g.
// call it as [_patient, _bodyPart, _gauge] call ACME_fnc_ivSiteDifficulty.
// _gauge is 14, 16, 18 or 20, defaulting to 16. 14g is the biggest bore and hardest, and 20g is the smallest and
// easiest.
// it returns [_patency, _feelRadius, _hitRadius, _maxHot].
params ["_patient", "_bodyPart", ["_gauge", 16], ["_site", 1]];
private _bp = toLower _bodyPart;

// the ej: a big, superficial neck vein. it is a forgiving target and is not governed by the peripheral systolic
// patency window, because a flat-pressure patient still has a visible and palpable ej. the gauge still scales the
// success margin. it is tunable.
if (_bp == "ej") exitWith {
    // the ej is a larger and more superficial vessel than a hand vein, so it stays the easier target. it was far
    // too easy: the hit radius ran 0.010 to 0.016 against 0.0015 to 0.0040 on a limb, which is four to six times
    // the width, and the vein could be hit almost anywhere on the neck.
    // it is now roughly twice a limb rather than five times. still forgiving, and it has to be aimed at.
    // the palpable band came down with it, from 0.034, for the same reason: a band that wide showed the vein
    // across most of the neck and did the aiming for the medic.
    // the range runs to 20 now that a 20g exists. it ran to 18, and with a 20g passed in, a linearConversion with
    // clamping would have returned the 18g value, so a 20g would have read as an 18g on the neck and nowhere else.
    private _hitEJ = linearConversion [14, 20, _gauge,
        (missionNamespace getVariable ["ACME_iv_ejHitMin", 0.0045]),
        (missionNamespace getVariable ["ACME_iv_ejHitMax", 0.0075]), true];
    [1, (missionNamespace getVariable ["ACME_iv_ejFeel", 0.014]), _hitEJ, 1.0]
};

private _isLeg = _bp in ["leftleg", "rightleg"];

// the ACM peripheral patency for the perfusing case, which is systolic-driven.
private _sys = 90;
private _bp2 = if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
    [_patient] call ace_medical_status_fnc_getBloodPressure  // [diastolic, systolic], including the ACME shock offset.
} else { [60, 90] };
if (_bp2 isEqualType [] && {count _bp2 >= 2}) then { _sys = _bp2 select 1; };

private _patency = if (_isLeg) then {
    linearConversion [60, 80, _sys, 0, 1, true]
} else {
    linearConversion [70, 90, _sys, 0, 1, true]
};

// map the patency into feel and stick difficulty.
// these are half-widths of the thin vein, in body-width fractions. the body rect is about 1267 px wide at 1080p, so
// 0.001 is about 1.3 px. veins are thin, so the color only starts a few px out and the stick zone is pinpoint.
// feelradius is how close, horizontally, before the feel dot starts warming, at about 4 to 10 px.
// hitradius is the success margin, and it is pinpoint, at about 2 to 5 px, gauge-scaled.
// maxhot gates green, because a flat vein never lets the dot reach green.
private _feelRadius = linearConversion [0, 1, _patency, 0.0030, 0.0080, true];
private _hitRadius  = linearConversion [0, 1, _patency, 0.0015, 0.0040, true];
private _maxHot     = linearConversion [0, 1, _patency, 0.35, 1.0, true];

// the needle gauge scales the success margin, which is the precision required. 20g, the smallest bore, gets the
// most forgiving margin and 14g, the big bore, the tightest. it is a multiplier on _hitRadius.
private _gaugeMult = switch (_gauge) do {
    case 14: { 0.65 };  // a big bore, so it is harder with a tighter target.
    case 16: { 0.85 };
    case 18: { 1.15 };  // a small bore, so it is a touch more forgiving.
    case 20: { 1.35 };  // The smallest bore has the most forgiving placement margin.
    default { 1.0 };
};
_hitRadius = _hitRadius * _gaugeMult;

// the vein itself, on top of the patient.
// the same casualty is not equally hard everywhere. a median cubital at the elbow is large, shallow and tethered,
// and a metacarpal vein on the back of the hand is small, loose and rolls away from the needle. two sticks on one
// patient should not carry the same difficulty just because the blood pressure is the same for both.
// see fn_ivveincatalog for the properties and why each vein has the numbers it does.
private _vein = [_bodyPart, _site] call ACME_fnc_ivVeinCatalog;
if ((count _vein) > 0) then {
    // caliber widens the target. a big vein is a bigger thing to hit, and that is most of why the fossa is easy.
    _hitRadius = _hitRadius * (linearConversion [0.3, 1.0, (_vein getOrDefault ["caliber", 0.7]), 0.72, 1.25, true]);
    // depth is felt rather than hit. a deep vein is no smaller once you are on it, it is only harder to find, so
    // this moves the palpation radius and leaves the stick alone.
    _feelRadius = _feelRadius * (linearConversion [0, 1, (_vein getOrDefault ["depth", 0.3]), 1.15, 0.65, true]);
    // roll is the one that actually loses sticks. the vein was there when you felt it and it is not there when the
    // needle arrives, which is why a hand vein misses on a stick that looked right.
    _hitRadius = _hitRadius * (linearConversion [0, 1, (_vein getOrDefault ["roll", 0.3]), 1.10, 0.70, true]);

    // is this cannula too big for this vein?
    // it is not forbidden, because a medic is allowed to try and finding out is the lesson. it is simply much
    // harder, and it gets harder the further past the limit of the vein you go.
    private _maxG = _vein getOrDefault ["maxG", 16];
    if (_gauge < _maxG) then {
        // gauge numbers run backwards, so a smaller number is a bigger cannula. each step over is a real penalty,
        // and a 14g into a metacarpal vein is three steps over.
        private _over = (_maxG - _gauge) / 2;
        _hitRadius = _hitRadius * ((1 - (0.28 * _over)) max 0.25);
    };
};

[_patency, _feelRadius, _hitRadius, _maxHot]
