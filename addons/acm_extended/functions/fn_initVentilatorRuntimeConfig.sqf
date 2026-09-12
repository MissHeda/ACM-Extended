/*
 * Phase 22 subsystem initialization: Ventilator technician, sound-overlap, barotrauma, sedation, zeroing and cough tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

ACME_vent_techCode       = "0000";  // red items, CALIBRATION and sw UPDATE. an empty string leaves the machine unlocked.
ACME_vent_sndOverlap     = 0.11;  // s of crossfade. the loop comes up this early under the startup tail, and the
                                    // the loop is held this long under the shutdown, so the turbine spool-up and spool-down run into the running
                                    // hum with no audible gap either way.
ACME_vent_baroPIPThreshold = 35;  // PIP (cmH2O) above which barotrauma accrues
// Normalized medication effect, not mg. This matches the capnography sedation gate.
ACME_sed_adequateThresh = call ACME_fnc_sedationThreshold; // compatibility display only; readers call the helper.
ACME_vent_zeroIntervalSecs = 300;  // how often the vent re-zeroes its transducers (z)
ACME_vent_zeroDurationSecs = 2.5;
ACME_vent_coughChance = 0.22;  // per 5 s roll, on an intubated, unsedated and unparalyzed patient.
