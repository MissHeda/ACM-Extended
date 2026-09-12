/*
 * Phase 20 subsystem initialization: Obtundation, impaired-consciousness and recovery/input-lock tunables.
 *
 * This is a behavior-preserving extraction from ACME_fnc_postInit. Keep runtime
 * event/PFH ownership in postInit or the owning subsystem; this helper only establishes
 * startup state and tunables in the same order as before.
 */

// obtunded state, a clouded consciousness. it gives a dim soft-vignette swim, motion blur and head sway.
// every episode ragdolls briefly into prone. lighter obtundation stays prone and can crawl. deeper obtundation
// rolls onto the back and settles into the fixed basicdriveroutdying pose.
ACME_obtunded_fixedAnim = "ACME_ObtundedBack";  // obtunded-on-back pose. it acts the lying-wounded look with the forced-freelook lock set. set it to "ACM_LyingState" to use ACM's pose instead.
// runtime guard. if the custom animation state failed to compile into the game config, a switchmove to it
// does nothing and the casualty stays face-down. fall back to ACM's own pose.
if (!isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> "ACME_ObtundedBack")) then {
    ACME_obtunded_fixedAnim = "ACM_LyingState";
};
ACME_obtunded_proneAnim = "AmovPpneMstpSnonWnonDnon";
ACME_obtunded_useRagdoll = false;  // legacy knob; B49 never ragdolls on obtundation entry.
ACME_obtunded_wakeSettle = 0.10;  // delay after ACE wake before beginning the collapse
ACME_obtunded_ragdollTime = 0.85;  // PhysX collapse time before returning to conscious prone
ACME_obtunded_proneSettle = 0.40;  // time allowed for the prone action/animation to settle
ACME_obtunded_proneHold = 0.35;  // visible prone beat before rolling into the fixed posture
ACME_obtunded_fixedSettle = 0.40;  // verify/fallback delay after requesting basicdriveroutdying
ACME_obtunded_dimMin = 0.70;  // brightness floor (higher = more visible)
ACME_obtunded_dimMax = 1.00;  // brightness ceiling (1.0 = normal)
ACME_obtunded_swellRate = 55;  // vision swim speed (deg/sec)
ACME_obtunded_blur = 1.0;  // legacy alias; active B49 blur stays on ACE severe-pain scale 0..1.
ACME_obtunded_blurFadeIn = 0.18;
ACME_obtunded_blurFadeOut = 0.45;
ACME_obtunded_blurPulseRate = 42;
ACME_obtunded_blurPulseDepth = 2.8;  // DynamicBlur (motion-coupled; smears on head turn)
ACME_obtunded_swayPower = 0.07;  // groggy head-sway amplitude (0 = off)
ACME_obtunded_swayInterval = 2.0;  // seconds between sway re-triggers
ACME_obtunded_muffleLevel = 0.35;  // master volume while obtunded (1 = normal; lower = duller)
ACME_obtunded_muffleFade = 1.5;  // fade time (s) in/out of the muffle
// fixed and supine obtundation input lock. it uses the real bindings of the player. it does not block mouse
// movement, so the casualty can still turn and look with the head, while it suppresses the locomotion, stance,
// fire, reload and throw inputs.
ACME_obtunded_blockedActions = [
    "MoveForward", "MoveBack", "MoveLeft", "MoveRight",
    "MoveFastForward", "MoveSlowForward", "Evasive", "Turbo", "TurboToggle",
    "TurnLeft", "TurnRight", "Stand", "Crouch", "Prone",
    "AdjustUp", "AdjustDown", "AdjustLeft", "AdjustRight",
    "LeanLeft", "LeanRight", "LeanLeftToggle", "LeanRightToggle", "GetOver",
    "Fire", "Throw", "ReloadMagazine", "SwitchWeapon", "NextWeapon", "PrevWeapon",
    "Handgun", "PrimaryWeapon", "SecondaryWeapon", "Binocular"
];
// physiological auto-obtundation band, with enter and exit hysteresis on SpO2 and MAP.
ACME_obtunded_spo2EnterLo = 70;  // SpO2 floor of the band. ACM knocks out for certain here. from 80 down to this it is a per-tick roll, and obtundation covers the whole of it.
ACME_obtunded_spo2EnterHi = 88;  // below this, and at or above the floor, they are obtunded.
ACME_obtunded_spo2Recover = 92;  // climb to here to leave the band
ACME_obtunded_mapEnterLo = 55;  // MAP floor of the band. ACM raises fatal vitals below this, so it is cardiac arrest rather than unconsciousness.
ACME_obtunded_mapEnterHi = 65;  // below this, and at or above the floor, they are obtunded.
ACME_obtunded_mapRecover = 70;  // climb to here to leave the band
// entry is sustained rather than instant. see fn_obtundedauto.
ACME_obtunded_dwellEnter = 8;   // seconds continuously in the band before it takes them. a dip does not count.
ACME_obtunded_hardSpO2 = 83;    // below this it is immediate. no amount of waiting makes the low eighties benign.
ACME_obtunded_hardMAP = 59;     // below this it is immediate.
ACME_obtunded_refractory = 45;  // seconds of grace after recovering on their own vitals.
ACME_obtunded_dwellReEnter = 20;  // the longer dwell that applies inside that grace window.
ACME_obtunded_blinkDuration = 0.6;  // length of one blink, the close and reopen, in seconds. slower reads as heavier-lidded.
ACME_obtunded_blinkIntervalMin = 3.0;  // min seconds between blinks
ACME_obtunded_blinkIntervalMax = 5.5;  // max seconds between blinks
ACME_obtunded_getUpTime = 5.5;  // seconds for the complete Get Up movement while awake-but-obtunded.
ACME_obtunded_sprintFallChance = 0.35;  // one roll per fresh sprint attempt.
ACME_obtunded_sprintFallDuration = 1.25;  // engine-ragdoll/down interval; never sets ACE medical unconsciousness.
ACME_obtunded_sprintFallCooldown = 2.5;
ACME_obtunded_blurWaveMin = 0.12;  // ACE severe-pain DynamicBlur scale is 0..1.
ACME_obtunded_blurWaveMax = 1.00;
ACME_obtunded_blurCycle = 4.5;  // seconds for one full fade-out/fade-in wave.
ACME_obtunded_lucidBlur = 0.08;
ACME_obtunded_vignetteMin = 0.10;
ACME_obtunded_vignetteMax = 0.34;
// two-posture obtundation and the consciousness budget.
ACME_obtunded_proneEnable    = false;  // legacy/inert since B49; awake obtundation never forces a posture.
ACME_obtunded_backSpO2       = 86;  // legacy/inert posture threshold retained for compatibility.
ACME_obtunded_backMAP        = 62;  // legacy/inert posture threshold retained for compatibility.
ACME_obtunded_postureHys     = 2;  // legacy/inert.
ACME_obtunded_crawlSpeedCoef = 0.15;  // legacy/inert.
ACME_obtunded_crawlMaxSpeed  = 0.35;  // legacy/inert.
// getting up out of the lying state. UnconsciousOutProne is the vanilla roll onto the stomach and push up, and
// it is the same animation ACM used, at core/functions/fnc_getUp.sqf:23. the difference is the priority: ACM
// played it at 2, switchMove, which skips the transition and snaps. 1 is playMoveNow, which plays it.
// set ACME_getUp_priority to 2 for the old snap.
ACME_getUp_anim     = "UnconsciousOutProne";
ACME_getUp_animTime = 1.6;   // how long the roll is held before the backstop checks whether it took.
ACME_getUp_priority = 1;
ACME_obtunded_rollToBackAnim = "AinjPpneMstpSnonWrflDnon_rolltoback";  // prone bridge into the obtunded-back fixed pose
ACME_obtunded_rollSettle     = 0.8;  // seconds to let the roll-to-back play before we request the fixed pose.
ACME_ko_mercySeconds         = 300;  // hard cap on a single continuous black-screen, true-ko, stretch, in seconds.
ACME_ko_mercyHoldSeconds     = 45;  // after the cap, how long to force the awake-but-down hold whatever the vitals say.
ACME_ko_systemEnable         = true;  // master for the down-and-out system, the budget and the posture cascade. false gives the original simple back-stuck obtundation with no time cap.
ACME_obtunded_careGraceMax   = 25;  // seconds a being-treated mark lasts if the treatment-end event is missed. it auto-clears so the rolls resume.
ACME_ko_wakeFloorSpO2        = 85;  // the SpO2 the mercy backstop stabilizes you to, so ACE does not re-ko you at once.
ACME_ko_wakePainCap          = 0.5;  // pain ceiling applied by the mercy backstop, so pain does not re-ko you.
