// HPMK body overlays: the unwrapped blanket when prepped, and the wrapped body when wrapped. both are runtime
// and on top.
["ace_medical_gui_updateBodyImage", {_this call ACME_fnc_updateHpmkImage}] call CBA_fnc_addEventHandler;
// AAJT-s. hide the generic leg tourniquet icon on a leg the AAJT-s has tourniqueted. this runs after ACM has
// shown it.
// NA3: real tourniquets remain visible independently of the AAJT.
// ej. ACM's body-image iv loop skips the head, so an established external jugular shows no icon. this draws a
// small iv marker over the neck whenever the patient has a head iv. the position knobs below are tunable live,
// so nudge them in game.
["ace_medical_gui_updateBodyImage", {_this call ACME_fnc_updateEJImage}] call CBA_fnc_addEventHandler;
// an unsecured tube works its way out when a medic handles the casualty.
// every one of these is a real handling event, and every one is a chance for the tube to move. nothing here
// fires on a timer. leave the casualty alone and the tube stays where it is.
// the severity scales with how rough the handling is. a carry and a load move a tube more than a short drag.
// CBA_fnc_addEventHandler takes an event name and a function, and nothing else. it ignores a third argument
// silently, so _thisargs inside the handler is undefined and the handler throws the moment the event fires. one
// of these events is ace_medical_treatment_headTurned, which is the path the check-breathing and head-lift
// animations run through, so this broke both of them. the severity is compiled into the handler instead.
// it is also wrapped, so a fault in here can never take down another listener on the same event.
{
    _x params ["_evt", "_sev"];
    [_evt, compile format ["
        params ['_a', '_b'];
        private _pt = if ((_b isEqualType objNull) && {!isNull _b}) then {_b} else {_a};
        if (!isNil '_pt' && {_pt isEqualType objNull} && {!isNull _pt}) then {
            [_pt, %1] call ACME_fnc_ettMigrate;
        };
    ", _sev]] call CBA_fnc_addEventHandler;
} forEach [
    ["ace_dragging_startedDrag",   0.7],
    ["ace_dragging_startedCarry",  1.0],
    ["ace_common_loadedPersonEH",  1.4],
    ["ace_unloadPersonEvent",      1.4],
    ["ace_medical_treatment_headTurned", 0.8],
    ["ACM_airway_headTurned",      0.8]
];

["ace_medical_gui_updateBodyImage", {_this call ACME_fnc_updateETTubeImage}] call CBA_fnc_addEventHandler;
ACME_ejBodyMarkX = 0.500;  // ej neck marker. horizontal center, 0 to 1 of the body-image rect width.
ACME_ejBodyMarkY = 0.140;  // ej neck marker. height down the figure, 0 to 1 of the rect height, just below the head.
ACME_ejBodyMarkW = 0.075;  // ej neck marker: width  (fraction of rect width)
ACME_ejBodyMarkH = 0.045;  // ej neck marker. height as a fraction of the rect height. w and h split so it can read square.
// acme_ejbodymarktex = "\acm_extended\ui\items\establish_iv_ca.paa"; swap the marker texture here if you
// want a different one.

// head injuries into TBI.
ACME_tbi_headTriggerDamage = 0.25;  // head body-part damage that arms a TBI
ACME_tbi_icpEarlyTell      = 18;  // ICP at which pupils start reading "sluggish"
// any wound fires this. the handler reads the head damage and inits or escalates the TBI cascade.
// NA3: headInjuryTBI receives only new wound records from the native wounds handler.

// iatrogenic pneumothorax from a failed or missed NAR SPEAR insertion. it runs where the patient is local, so
// ACM's deterioration pfh ticks correctly. it mirrors zeus inflictchestinjury "developing pneumothorax", case
// 0. it flags a chest injury and seeds a low-grade ptx that can escalate to tension over time.
["ACME_CS_inflictPneumo", {
    params ["_patient"];
    if (isNull _patient || {!alive _patient}) exitWith {};
    [_patient, true] call ACM_breathing_fnc_setChestInjuryState;
    [_patient] call ACM_breathing_fnc_handlePneumothorax;
}] call CBA_fnc_addEventHandler;
