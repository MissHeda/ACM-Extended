// the third dimension: how far in.
// call it as [_dir] call ACME_fnc_laryngoScroll, where _dir is +1 for further in and -1 for back out.
// a mouse gives two axes and this minigame needs three: elevation, the lift, rotation, the pry, and depth. depth
// goes on the wheel, and the wheel is phase contextual, so it always means the same thing to the hand: push the
// live instrument further in, or draw it back out.
// the blade phases, scopeheld, inserted, lifting and held, drive the blade depth.
// the tube phases, tubeheld and tubing, drive the tube advance.
// they never fight, because taking the tube freezes the blade at whatever depth it was set to. that mirrors the
// real sequence: you find your depth, you lift, and then your left hand stops changing anything.
// blade depth does not get a score of its own. it multiplies the two systems that already exist.
// too shallow puts the tip on the tongue base rather than in the vallecula, so lifting rolls the tongue instead of
// engaging the hyoepiglottic ligament and the same pull buys much less view.
// correct seats the tip in the vallecula, giving full value for the lift and the least load on the teeth.
// too deep is past the epiglottis, so the view closes again and the blade is levering on the wrong structure.
// the wrong depth in either direction means more tooth load per unit of off-axis motion, so a medic at the wrong
// depth finds themselves fighting the airway and hears the teeth start creaking for it.
params ["_dir"];
if (!(_dir isEqualType 0) || {!finite _dir} || {_dir == 0}) exitWith {};
// High-resolution wheel reports are one bounded impulse, never a multi-detent injury burst.
_dir = if (_dir > 0) then {1} else {-1};
private _state = uiNamespace getVariable ["ACME_laryngo_state", "idle"];
// a placed airway does not get fed further in or drawn back out on the wheel.
if (_state == "complete") exitWith {};

switch (true) do {
    case (uiNamespace getVariable ["ACME_laryngo_tubeInHand", false]): {
        private _ptB39 = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
        private _depthB39 = uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0];

        // B39 hard airway-reflex rule: an alive, perfusing, awake casualty will not tolerate
        // an orotracheal tube. The very first inward advance provokes immediate emesis and
        // expels the tube back to the tray. Sedation scores/stale paralysis flags never override
        // the actual awake state; true unconsciousness or arrest is required to bypass this guard.
        if (_dir > 0 && {!isNull _ptB39} && {alive _ptB39}
            && {!(_ptB39 getVariable ["ace_medical_inCardiacArrest", false])}
            && {!(_ptB39 getVariable ["ACE_isUnconscious", false])}
        ) exitWith {
            uiNamespace setVariable ["ACME_laryngo_tubeVel", 0];
            uiNamespace setVariable ["ACME_laryngo_tubeDepth", (_depthB39 max 0.08)];
            [_ptB39, "awakeTube"] call ACME_fnc_laryngoConsequence;
            ["awake", true] call ACME_fnc_laryngoTubeEject;
        };

        // the blade is what moves the tube, in and out.
        // a tube is advanced and withdrawn under direct vision. without the laryngoscope in the mouth there is nothing
        // holding the tongue off the cords and nothing to see the tube against, so the hand on the tube has no idea
        // what it is doing. backing it out used to be allowed at any time, which meant a tube could be drawn out of a
        // patient with no view at all.
        // so both directions need the blade in. take the scope out whenever you want and the tube simply stays where
        // it is, which is the honest result: a tube that is in is in, and it does not move again until you can see.
        private _bladeInNow = (uiNamespace getVariable ["ACME_laryngo_state", ""]) in ["inserted","lifting","held","seated"];
        private _liftNow = uiNamespace getVariable ["ACME_laryngo_lift", 0];
        private _liftNeed = missionNamespace getVariable ["ACME_laryngo_liftThresh", 0.36];
        private _fullView = _bladeInNow
            && {uiNamespace getVariable ["ACME_laryngo_airwayOpen", false]}
            && {_liftNow >= _liftNeed};

        // Once any part of the tube is in the mouth/airway, it can be repositioned or withdrawn.
        // Doing so without a fully elevated tongue is deliberately unsafe and provokes a gag/vomit
        // reflex, but we do not magically freeze the tube in place. Rate-limit one reflex per
        // manipulation burst so a single wheel event cannot create several emesis events.
        if (_depthB39 > 0.001 && {!_fullView} && {CBA_missionTime >= (uiNamespace getVariable ["ACME_laryngo_manipGagNext", 0])}) then {
            uiNamespace setVariable ["ACME_laryngo_manipGagNext", CBA_missionTime + 0.8];
            if (!isNull _ptB39) then {[_ptB39, "tubeManip"] call ACME_fnc_laryngoConsequence;};
        };

        // A fresh tube still requires a real laryngoscopic view for the initial inward pass.
        if (_dir > 0 && {_depthB39 <= 0.001} && {!_fullView}) exitWith {
            uiNamespace setVariable ["ACME_laryngo_tubeVel", 0];
        };
        // it only advances while the tube is actually gripped, with the left mouse held. withdrawing needs the blade
        // but not the grip, because letting go of the free end and drawing it back is one motion.
        private _grip = uiNamespace getVariable ["ACME_laryngo_tubeGrip", false];
        if (_dir > 0 && {!_grip}) exitWith {};
        // A blocked advance is one missed placement until the medic releases and re-aims.
        // Neither a held wheel burst nor a momentary loss of view is several attempts.
        if (_dir > 0 && {_depthB39 <= 0.001} && {!(uiNamespace getVariable ["ACME_laryngo_tubeCanFeed", false])}) exitWith {
            uiNamespace setVariable ["ACME_laryngo_tubeVel", 0];
            uiNamespace setVariable ["ACME_laryngo_tubeBalkUntil", diag_tickTime + 0.70];
            if (!(uiNamespace getVariable ["ACME_laryngo_missLatched", false])) then {
                uiNamespace setVariable ["ACME_laryngo_missLatched", true];
                [uiNamespace getVariable ["ACME_laryngo_patient", objNull], "miss"] call ACME_fnc_laryngoConsequence;
            };
        };

        // slidey. the wheel used to add straight to the depth, so every click was a hard jump from one frame to the next.
        // it adds velocity now and the depth integrates it, so a scroll starts the tube moving and it coasts to a stop
        // over a short decay. feeding is a push rather than a series of steps, and stopping scrolling glides to a halt
        // instead of freezing mid-frame.
        private _step = missionNamespace getVariable ["ACME_laryngo_tubeStep", 0.055];
        // what is holding it. a collar is a strap and simply refuses. a cuff is a balloon in the trachea: it gives a
        // little, tugs back, and tears the cords if you keep hauling on it.
        ([] call ACME_fnc_laryngoTubeAnchor) params ["_anLock", "_anRes", "_anWhy"];
        if (_anLock) exitWith {
            if (CBA_missionTime > (uiNamespace getVariable ["ACME_laryngo_anchorNagNext", 0])) then {
                uiNamespace setVariable ["ACME_laryngo_anchorNagNext", CBA_missionTime + 2];
                [_anWhy, 2.5] call ace_common_fnc_displayTextStructured;
            };
        };

        private _vel = uiNamespace getVariable ["ACME_laryngo_tubeVel", 0];
        private _imp = _step * (missionNamespace getVariable ["ACME_laryngo_tubeImpulse", 6]);
        if (_anRes > 0) then {
            // the cuff eats most of the effort. what gets through is a fraction, so the tube creeps rather than slides and
            // the medic can feel that something is wrong before they have done any harm.
            _imp = _imp * (1 - _anRes);
            // forcing it. every click against an inflated cuff is the balloon being dragged at the cords. count them, and
            // past a threshold that is a tear.
            private _haul = (uiNamespace getVariable ["ACME_laryngo_cuffHaul", 0]) + 1;
            uiNamespace setVariable ["ACME_laryngo_cuffHaul", _haul];
            if (CBA_missionTime > (uiNamespace getVariable ["ACME_laryngo_anchorNagNext", 0])) then {
                uiNamespace setVariable ["ACME_laryngo_anchorNagNext", CBA_missionTime + 2.5];
                [_anWhy, 2.5] call ace_common_fnc_displayTextStructured;
            };
            if (_haul >= (missionNamespace getVariable ["ACME_ETT_cuffTearAt", 14])) then {
                uiNamespace setVariable ["ACME_laryngo_cuffHaul", 0];
                private _pt = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
                if (!isNull _pt) then { [_pt, 3] call ACME_fnc_laryngoPersistBleed; };
            };
        } else {
            uiNamespace setVariable ["ACME_laryngo_cuffHaul", 0];
        };
        // past the carina.
        // this used to be a hard detent. the tube arrived at the ideal depth and stopped dead, and going deeper took
        // nine deliberate pushes against a zeroed impulse. that decided for the medic where the tube belongs, and it is
        // not the game's decision to make: a tube goes as deep as the hand pushing it, and the consequence of pushing
        // it too far is the thing worth teaching.
        // so nothing is blocked now. the tube advances as far as it is fed, and one advisory is given the first time
        // it passes the seating depth so the medic knows they have crossed it rather than being stopped at it.
        // the consequence still arrives on its own. fn_ettmainstemtick reads the depth and runs the one-lung picture:
        // the capnograph stays reassuring while the saturation drifts and the airway pressure climbs, and the medic has
        // to notice the numbers disagreeing. that is the lesson, and it lands because they chose the depth.
        private _idealF = uiNamespace getVariable ["ACME_laryngo_idealFrame", 8];
        private _curF = 1 + (round ((uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0]) * 7));
        if (_dir > 0 && {_curF >= _idealF}) then {
            if (!(uiNamespace getVariable ["ACME_laryngo_pastCarinaSaid", false])) then {
                uiNamespace setVariable ["ACME_laryngo_pastCarinaSaid", true];
            };
        } else {
            // drawn back to depth or shallower, so the advisory arms again for the next time they pass it.
            if (_dir < 0 && {_curF < _idealF}) then { uiNamespace setVariable ["ACME_laryngo_pastCarinaSaid", false]; };
        };

        _vel = _vel + (_dir * _imp);
        private _vmax = missionNamespace getVariable ["ACME_laryngo_tubeVelMax", 1.2];
        uiNamespace setVariable ["ACME_laryngo_tubeVel", ((_vel max (-_vmax)) min _vmax)];
    };

    case (_state in ["scopeHeld", "inserted", "lifting", "held"]): {
        private _step = missionNamespace getVariable ["ACME_laryngo_depthStep", 0.05];
        private _d = ((uiNamespace getVariable ["ACME_laryngo_depth", 0.5]) + (_step * _dir)) max 0 min 1;
        uiNamespace setVariable ["ACME_laryngo_depth", _d];
    };
};
