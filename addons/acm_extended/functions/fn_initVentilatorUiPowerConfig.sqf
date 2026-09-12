/*
 * Phase 22 subsystem initialization: Ventilator battery, brightness, panel geometry and alarm-volume tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// ventilator battery.
// the sparrow is turbine-driven and needs no oxygen to ventilate, so gas is not the constraint. power is. the
// real spec runs up to 4.5 hours, which is a whole mission with nothing to manage, so this is shortened on
// purpose. it exists to create pressure. a ventilated casualty should be a reason to
// move.
ACME_vent_batteryMinutes         = 55;  // at gentle settings. hard settings burn it faster. see the load mults.
ACME_vent_batteryRechargeMinutes = 90;  // on vehicle/aircraft power with the engine running
ACME_vent_batteryLowPct          = 25;
ACME_vent_batteryCritPct         = 10;
ACME_vent_battPeepMult           = 1.35;  // PEEP 20 vs 5
ACME_vent_battRateMult           = 1.30;  // rr 35 vs 10
ACME_vent_battPipMult            = 1.40;  // PIP 50 vs 20: stiff lungs make the turbine work hardest

// ventilator display brightness.
// index 0 is the robust night setting and is unreadable to the naked eye on purpose. 0.055 of normal output is
// a faint glow, not a dim screen. under image intensifiers it lifts to 0.85 and reads normally. that makes the
// setting a real tradeoff, because you cannot use the panel without dropping goggles, rather than a free
// stealth option.
ACME_vent_scrollCooldown = 0.065;  // was 0.09. the dial detent sounds are sped up 1.5x to match, so the click still lands.
                                   // inside one step at the maximum scroll rate, rather than smearing across two.
                                   // four brightness levels, indexed 1 to 4. level 1 is the robust night setting: unreadable to the naked eye and
                                   // readable again under image intensifiers. it stays at the bottom of the range rather than being dropped to
                                   // make four, because that setting is the whole reason this control is interesting. index 0 is a spare that only
                                   // a corrupted value reaches, and it resolves to night as well, so it fails dark rather than bright.
ACME_vent_brightSteps  = [0.055, 0.055, 0.45, 0.72, 1.0];
ACME_vent_nightNvgMult = 0.85;
// the level every start comes up at, set in fn_ventBootStart. 3 is 0.72, three quarters up the ladder. a machine
// must never boot into level 1, the robust night setting, because that is unreadable to the naked eye.
ACME_vent_brightDefault = 3;
// the dark panel rect, as fractions of the screen rect. the bottom runs a little INTO the bezel bar of the art so
// no hairline of lighter case shows between the black square and the black frame. nudge the bottom if the art
// changes.
// THE BOTTOM IS DERIVED, NOT NUDGED. it was moved by hand three times and left a gap every time.
// fn_ventPanelInit:377 already records the two measurements needed, taken off the decoded texture: the screen
// rect runs y 0.4185 to 0.5879 of the face, and the opaque extent of the inlay art runs y 0.41846 to 0.58887.
// so the art reaches 0.58887, and in screen-rect fractions that is (0.58887 - 0.4185) / 0.16940 = 1.00573.
// THE ART EXTENDS PAST THE BOTTOM OF THE SCREEN RECT. every earlier value, 0.8705, 0.8780 and 0.8900, was inside
// the rect and could not have reached the frame no matter how far it was pushed, because the target sits beyond
// the end of the range that was being nudged.
// 1.0100 clears it with a margin. overshoot is free here: the bezel below is black, this branch draws the
// substrate with nothing on top of it, and the whole point is that no lighter case shows through.
// the side bleed comes from the same comment. the art overhangs the rect by 0.00943 of the screen width on the
// left and 0.00684 on the right, so 0.006 was short on the left. 0.0120 covers both.
ACME_vent_offScreenTop    = 0.1347;
ACME_vent_offScreenBottom = 1.0100;
ACME_vent_offScreenBleed  = 0.0120;
// four volume levels, indexed 1 to 4 by the popup. level 3 stays at 1.0, so the default balance does not
// change.
ACME_vent_alarmVolSteps = [0.35, 0.65, 1.0, 1.6];
