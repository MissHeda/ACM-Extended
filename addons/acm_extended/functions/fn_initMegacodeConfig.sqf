/*
 * Phase 20 subsystem initialization: Megacode Kelly training-manikin presentation and timing tunables.
 *
 * This is a behavior-preserving extraction from ACME_fnc_postInit. Keep runtime
 * event/PFH ownership in postInit or the owning subsystem; this helper only establishes
 * startup state and tunables in the same order as before.
 */

// megacode kelly tunables, for the zeus training manikin.
ACME_megacode_restAnim   = "ACM_LyingState";  // the pose the manikin is locked into. it never stands, crouches or prones.
ACME_megacode_animInTime = 1.6;  // seconds before the operator's radio-talk in -> loop hand-off
ACME_megacode_animOutTime= 1.4;  // seconds before the radio-talk out releases on panel close
ACME_megacode_sweepSecs  = 3.4;  // monitor sweep duration across one trace lane
ACME_megacode_waveCols   = 400;  // columns per waveform lane. a higher value is smoother with thinner steps. about 176 was blocky.
ACME_megacode_waveColSecs = 0.024;  // seconds per column, the sweep time-base. the window is wavecols times wavecolsecs.
                                             // beats across = window * hr/60. fewer secs or more cols packs in more beats and stretches less.
ACME_megacode_dummyHoseOffset  = [0, 0.32, 0.12];  // cable attach on the manikin (model space: chest)
ACME_megacode_laptopHoseOffset = [0, 0.13, 0.035];  // cable plug on the laptop, in model space. +y after the 180 deg turn is the patient-facing side.
ACME_megacode_ropeSlack        = 0.2;  // extra rope length beyond the laptop to dummy distance. this is the cable tuner.
ACME_megacode_ropeSegments     = 0;  // rope segment count (0 = engine default, max 63); cable tuner
ACME_megacode_laptopPosOffset  = [0, 0, 0];  // legacy laptop-position offset. the sliders were removed and this stays callable.
ACME_megacode_ropeEndPitch     = -35;  // laptop-side wire-end steering in deg. the pitch tips the wire down into the laptop rather than straight up.
ACME_megacode_ropeEndYaw       = 0;
ACME_megacode_ropeEndRoll      = 0;
ACME_megacode_ropeEndStub      = 0.12;  // wire-end steering anchor offset length in m. larger gives more leverage. the cable tuner calls it wire reach.
ACME_megacode_laptopPitch      = 0;  // deprecated. the laptop orient was replaced by laptopposoffset and this is kept for back-compat.
ACME_megacode_laptopYaw        = 0;
ACME_megacode_laptopRoll       = 0;
ACME_megacode_deathTime  = 240;  // seconds pulseless, with no ROSC and CPR pausing the clock, before the manikin is declared dead.
ACME_megacode_deathBeat  = 3.0;  // seconds the flatline and unconscious death is held before the auto-reset.
ACME_megacode_scenarioPace = 1.0;  // scenario stage-time multiplier. 0.5 is twice as fast and 2.0 is half speed.
