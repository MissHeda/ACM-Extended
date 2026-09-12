// keeping the airway open, one re-grip at a time.
// call it as [] call ACME_fnc_laryngoRegrip, bound to a key and pressed rhythmically.
// once the airway is open the lift no longer locks. it decays, and every tap of this key restores a small amount,
// eased in over a moment so the blade visibly nudges up in smooth increments rather than snapping. hold the
// rhythm and the view holds, and fall behind and it closes on you. that leaves the mouse completely free for the
// tube, which is the two-handed feel: the left hand keeping the airway open and the right hand feeding the tube.
// this is a rhythm rather than a mash. the grip fades while the key is held, so a fresh press is what restores it.
// re-gripping faster than the airway can yield does not help: past the ceiling the extra travel has nowhere to go,
// because the tongue is already fully compressed, and it goes into overpressure instead. enough of that and the
// blade is being driven into an airway that has stopped yielding, which trips the trauma consequences.
private _state = uiNamespace getVariable ["ACME_laryngo_state", "idle"];
// only once the airway is actually open. during the lift itself the mouse drag is the input, and letting taps
// contribute there would let a player bypass the technique scoring by tapping instead of pulling correctly.
if !(_state in ["held", "tubeHeld", "tubing"]) exitWith {};
if (uiNamespace getVariable ["ACME_laryngo_done", false]) exitWith {};

private _now = diag_tickTime;

// debounce, so a held-down key or a bouncing switch cannot substitute for actual taps.
private _last = uiNamespace getVariable ["ACME_laryngo_regripLast", -99];
if ((_now - _last) < (missionNamespace getVariable ["ACME_laryngo_regripDebounce", 0.11])) exitWith {};
uiNamespace setVariable ["ACME_laryngo_regripLast", _now];

// the ceiling is full tongue compression, which is the lift threshold, plus a little headroom. past that the
// tongue has nothing left to give and any further travel becomes overpressure.
private _ceil = (uiNamespace getVariable ["ACME_laryngo_liftThresh", 0.6])
              * (missionNamespace getVariable ["ACME_laryngo_regripHeadroom", 1.08]);
private _lift = uiNamespace getVariable ["ACME_laryngo_lift", 0];
private _bump = missionNamespace getVariable ["ACME_laryngo_regripBump", 0.135];

// depth still matters here. a blade at the wrong depth gives back less for the same re-grip, so a medic who never
// found the vallecula has to tap faster to hold a worse view and pays for it in tooth load.
private _dq = uiNamespace getVariable ["ACME_laryngo_depthQual", 1];
_bump = _bump * (0.35 + (0.65 * _dq));

private _room = _ceil - _lift;
if (_room <= 0.001) then {
    // the tongue is already fully compressed, so the whole tap becomes overpressure.
    private _op = (uiNamespace getVariable ["ACME_laryngo_overPressure", 0]) + _bump;
    uiNamespace setVariable ["ACME_laryngo_overPressure", _op];
} else {
    if (_bump > _room) then {
        // part of the tap lands, and the remainder is driven into an airway that has stopped moving.
        uiNamespace setVariable ["ACME_laryngo_overPressure",
            (uiNamespace getVariable ["ACME_laryngo_overPressure", 0]) + (_bump - _room)];
        _bump = _room;
    };
    // eased in by the tick rather than applied instantly, so the blade rises smoothly.
    uiNamespace setVariable ["ACME_laryngo_liftPending",
        (uiNamespace getVariable ["ACME_laryngo_liftPending", 0]) + _bump];
};

// Regripping is silent; only an actual fracture has a sound.
