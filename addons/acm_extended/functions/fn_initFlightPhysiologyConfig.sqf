/*
 * Phase 22 subsystem initialization: Flight-noise, altitude-datum and G-loading physiology tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

ACME_flightNoise_enable = true;  // a medic cannot auscultate in a running airframe. the alarms stay audible and only attenuated.
ACME_flightNoise_alarmVol = 1.0;  // vent alarm volume inside a running airframe, against 1.3 on foot. it is slightly quieter and still clearly audible, because the engine and rotor noise of the airframe does the real masking.
ACME_altitude_enable = true;  // gas expansion + hypobaric hypoxia
// MAP sea-level datum. some terrains are authored with their base plate well above sea level, which makes raw
// getPosASL report a casualty standing on flat ground as being at altitude. these control the correction.
// ACME_altitude_datumMode: -1 auto-detects, 0 applies no correction and uses the raw asl, and a value above 0
// is an explicit datum in meters.
// ACME_altitude_datumThreshold: a terrain whose lowest point is above this is treated as an authoring offset
// rather than genuinely high ground. it sits at 3000 m on purpose. an afghan valley at 1000 to 2500 m, or an
// altiplano at about 3700 m at its highest inhabited point, should keep its real hypoxia, while a base plate
// parked at 6000 m is plainly not ground anyone authored as habitable. of the two possible mistakes, wrongly
// flattening a genuine high map only loses some hypoxia, but a failure to correct an offset map suffocates a
// casualty lying still on the ground, which is far more disruptive and far harder to diagnose in play.
ACME_altitude_datumMode      = -1;
ACME_altitude_datumThreshold = 3000;
ACME_altitude_minMetres = 500;  // hypoxia threshold; PTX uses actual pressure changes at every altitude

// flight g-loading, a maneuver against a hypovolemic casualty.
// a climb or a hard banked turn loads the casualty footward. a filled patient compensates and nothing happens.
// a hypovolemic one loses venous return and the pressure sags through the turn, then recovers when the aircraft
// settles. fill them before the flight. it reaches the cuff through peripheral resistance, like every other bp
// effect.
ACME_flightG_enable = true;
ACME_flightG_climbRateFull = 8;  // m/s climb at which the climb loading is maxed
ACME_flightG_bankFull = 0.72;  // vectorup z at max bank loading, about 44 deg of bank. 1.0 is wings level.
ACME_flightG_hypoStartL = 0.5;  // liters of blood deficit before g-loading starts to bite
ACME_flightG_hypoFullL = 2.0;  // deficit at which the effect is maximal
ACME_flightG_maxResistDrop = 28;  // max resistance units removed at full g on a fully hypovolemic casualty.
ACME_flightG_stepPerSec = 18;  // ease rate, so the pressure sags into the turn and recovers out of it.
