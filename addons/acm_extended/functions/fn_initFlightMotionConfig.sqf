/*
 * Phase 22 subsystem initialization: Vehicle-motion minigame shake and flight-chill tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// flight physiology and vehicle motion.
ACME_motion_enable = true;  // minigames shake in a moving vehicle
ACME_motion_vibAmplitude = 0.007;  // the airframe humming. micro. felt, not seen.
ACME_motion_manAmplitude = 0.055;  // the airframe banking. it is large and slow, and the severity lives here.
ACME_motion_vibTau = 1.10;  // seconds for the vibration to settle to a new level. nothing snaps.
ACME_motion_manTau = 0.75;  // seconds for a bank to ramp in and ramp back out
ACME_motion_taperSpeed = 100;  // below this airspeed the buzz falls away. a landing should feel like a landing.
ACME_motion_rotorIdle = 0.12;  // rotors turning on the deck. it is a gentle hum, not silence and not a cruise.
ACME_motion_envMin = 0.30;  // the lull floor. in a lull the cabin settles to 30 percent and you get a window.
ACME_motion_envRateA = 0.17;  // two incommensurate oscillators, so the swell never repeats
ACME_motion_envRateB = 0.29;  // and cannot be counted
ACME_motion_bumpAmp = 0.022;  // a discrete jolt. sharp attack, fast decay.
ACME_motion_bumpDur = 0.20;  // one jolt is over in a fifth of a second. it is a hit, not a wallow.
ACME_motion_burstMax = 3;  // rough air hits you up to three times in quick succession
ACME_motion_burstGapMin = 0.13;  // spacing within a burst
ACME_motion_burstGapMax = 0.34;
ACME_motion_bumpCooldownMin = 4;  // then real calm. the cooldown is what protects the window. if a bump could
ACME_motion_bumpCooldownMax = 14;  // land at any instant, there would be no safe moment to commit.
ACME_motion_force = 0;  // TEST: 1 = cruise hum, 2 = hard bank. works on foot.
ACME_flightChill_enable = true;  // airflow and altitude cool the casualty, straight into the lethal triad.
ACME_flightChill_rotorC = 4;  // deg c from rotor downwash alone, sitting on the deck
ACME_flightChill_windMaxC = 14;  // deg c from forward airspeed at the top of the curve
ACME_flightChill_hpmkFactor = 0.15;  // an HPMK cuts the chill to 15% of what it would be
