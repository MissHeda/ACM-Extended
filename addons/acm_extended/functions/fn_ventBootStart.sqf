// start the boot sequence. pressing power has to run the same three phases a cold open runs rather than dropping
// the operator onto a settings screen with the machine apparently already awake.
// 1. blackout: a dead black panel, with no inlay and no logo. it is the half beat between the press and the device
// waking.
// 2. splash: a white screen with the sparrow mark, and the jingle a beat into it.
// 3. handover: a short gap, then the self test takes over and the normal flow resumes at WEIGHT.
// this mirrors the chain in fn_ventpanelinit rather than replacing it, because init runs at dialog creation and
// this runs on a press, and folding the two together means restructuring a code path that currently works. the
// four timings are read from the same mission variables, so a re-cut of the audio still only needs one edit.

disableSerialization;

// THE DISPLAY BRIGHTNESS RESETS ON EVERY START, WITHOUT EXCEPTION.
// a machine that comes up carrying the last setting somebody left on it is a machine that comes up unreadable in
// daylight or blinding at night, and the operator finds that out while a casualty is waiting. a real device that
// has been off and on again comes up somewhere sensible.
// so this runs here, in the one place that means the machine is STARTING. it therefore covers the power button
// on the reverse face, a battery swap, which leaves the machine dark and needs a power press since r-56, and any
// other route that boots it. it does NOT run when the panel is merely reopened on a machine that was already on,
// because that is not a restart and the operator's setting should survive it.
// ACME_vent_brightSteps is [0.055, 0.055, 0.45, 0.72, 1.0], indexed 1 to 4 by the dial. level 3 is 0.72, which is
// three quarters up the ladder: bright enough to read in daylight and not so bright it wrecks night vision.
// level 1 is the robust night setting and is unreadable to the naked eye on purpose, which is exactly the state a
// machine must never boot into by accident.
uiNamespace setVariable ["ACME_vent_brightness", (missionNamespace getVariable ["ACME_vent_brightDefault", 3])];

private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

private _blackout    = missionNamespace getVariable ["ACME_vent_blackoutSec", 0.45];
private _jingleDelay = missionNamespace getVariable ["ACME_vent_jingleDelaySec", 0.5];
private _jingleLen   = missionNamespace getVariable ["ACME_vent_jingleSndLen", 1.675];
private _bootGap     = missionNamespace getVariable ["ACME_vent_bootGapSec", 0.25];

// a beat before anything happens. the power button is on the back, so at the moment it is pressed the operator is
// looking at the wrong side of the device. without this the blackout and splash were already over by the time
// they turned it round, and this is the window to flip and watch the sequence.
private _pre = missionNamespace getVariable ["ACME_vent_bootPreDelaySec", 1.0];

private _bT0 = diag_tickTime + _pre;
uiNamespace setVariable ["ACME_vent_bootT0", _bT0];
// blank it now rather than on the next tick. the tick owns hiding these for the rest of the sequence, and there is
// at least one frame between the press and the tick running, and on that frame the previous screen was still
// lit.
{
    private _c = _dlg displayCtrl _x;
    if (!isNull _c) then { _c ctrlShow false; };
} forEach [87712,87713,87716,87767,87768,87720,87721,87722,87723,87724,87725,87726,87727,87730,87731,87732,
           87733,87734,87735,87736,87737,87738,87769,87774,87739,87759,87761,87762,87763,87764,87740,87741,
           87742,87743,87744,87745,87746,87747,87748,87749,87752,87753,87750,87751,87780,87781,87782,87783,
           87784,87785,87786,87787,87790,87791,87792,87793,87794,87795,87796,87797,87754,87755,87756,87757,
           87800,87801,87802,87765,87766];

uiNamespace setVariable ["ACME_vent_bootDur", _blackout + _jingleDelay + _jingleLen + _bootGap];
uiNamespace setVariable ["ACME_vent_blackoutUntil", _bT0 + _blackout];  // _bT0 already includes the pre-delay.
// a power-on is a cold start: the machine forgets which screen it was on and comes up at WEIGHT like any other.
// leaving the last screen set would land the operator back in the menus the moment boot finished.
uiNamespace setVariable ["ACME_vent_startScreen", ""];
uiNamespace setVariable ["ACME_vent_selfTestPct", 0];

// the chain never makes the screen visible. it sets what the screen will look like and leaves whether it is shown
// at all to fn_ventflip, which owns that. calling ctrlshow true here lit the panel through the back of the
// device: the machine was face down and the display came on anyway.
private _shown = { !(uiNamespace getVariable ["ACME_vent_flipped", false]) };

[{
    params ["_bT0", "_dlg", "_shown"];
    if ((uiNamespace getVariable ["ACME_vent_bootT0", -1]) isEqualTo _bT0
        && {!isNull (uiNamespace getVariable ["ACME_vent_dlg", displayNull])}) then {
        // phase 1: dead black. the logo is hidden and the inlay blanked, so nothing on the panel is lit.
        (_dlg displayCtrl 87760) ctrlShow false;
        (_dlg displayCtrl 87702) ctrlSetText "";
        (_dlg displayCtrl 87714) ctrlShow false;
        private _sbg = _dlg displayCtrl 87710;
        _sbg ctrlSetBackgroundColor [0,0,0,1];
        _sbg ctrlCommit 0;
        if (call _shown) then { (_dlg displayCtrl 87702) ctrlShow true; _sbg ctrlShow true; };
        [] call ACME_fnc_ventPanelHideScreen;
    };
}, [_bT0, _dlg, _shown], _pre] call CBA_fnc_waitAndExecute;

// phase 2: the screen wakes. it is stamped with the boot t0 it belongs to and re-checks the dialog, so closing the
// panel mid-boot drops it rather than firing into a dead display or landing on top of a fresher boot.
[{
    params ["_bT0", "_dlg", "_shown"];
    if ((uiNamespace getVariable ["ACME_vent_bootT0", -1]) isEqualTo _bT0
        && {!isNull (uiNamespace getVariable ["ACME_vent_dlg", displayNull])}) then {
        // shown only if the front is facing the operator. flip back later and the tick picks it up from boott0, so the
        // sequence is never re-run and is simply revealed part way through.
        (_dlg displayCtrl 87760) ctrlShow (call _shown);
        (_dlg displayCtrl 87702) ctrlSetText "\acm_extended\ui\vent\ventway_sparrow_robust_menu_startup_inlay.paa";
        uiNamespace setVariable ["ACME_vent_inlayCur", "\acm_extended\ui\vent\ventway_sparrow_robust_menu_startup_inlay.paa"];
        (_dlg displayCtrl 87714) ctrlShow false;  // there is no alarm square on the startup inlay.
    };
}, [_bT0, _dlg, _shown], (_pre + _blackout)] call CBA_fnc_waitAndExecute;

// the jingle, a beat into the lit splash.
[{
    params ["_bT0"];
    if ((uiNamespace getVariable ["ACME_vent_bootT0", -1]) isEqualTo _bT0
        && {!isNull (uiNamespace getVariable ["ACME_vent_dlg", displayNull])}) then {
        playSound3D ["acm_extended\sound\vent_jingle_sfx.ogg", ACE_player, false, getPosASL ACE_player, 3, 1, 30];
    };
}, [_bT0], (_pre + _blackout + _jingleDelay)] call CBA_fnc_waitAndExecute;
