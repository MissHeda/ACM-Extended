/*
 * Phase 24 subsystem ownership: ACRE2 obtunded speech-pulse configuration and delayed language registration.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

// B65 ACRE2 obtunded babble.
// Babble is a speech-aware PULSE effect now, never a persistent obtunded language.  The hard master gate remains
// ACME_sys_obtunded: if Obtundation is disabled in CBA, no ACME babble pulse is authorized and any stale pulse is
// restored immediately.  These are internal timing tunables, not independent feature switches.
ACME_acre_babbleEnable = true;
ACME_acre_babbleId     = "ACME_Obtunded";
ACME_acre_commonId     = "ACME_Common";
ACME_acre_babbleReady  = false;
ACME_acre_babbleSafe   = false;
ACME_acre_babbleRegistered = false;
ACME_acre_ownsFallbackCommon = false;
ACME_acre_babbleTickSec = 0.04;

// At mild/recovering physiology, speech gets a short 0.18-0.30 s corruption roughly every 7-12 s of continuous
// talking.  At the severe edge of the awake-obtunded band it rises to 0.36-0.60 s roughly every 1.6-3.4 s.
// Silence always restores the real language immediately, so these do not accumulate while the player is quiet.
ACME_acre_babblePulseMildMin   = 0.18;
ACME_acre_babblePulseMildRand  = 0.12;
ACME_acre_babblePulseSevereMin = 0.36;
ACME_acre_babblePulseSevereRand= 0.24;
ACME_acre_babbleGapMildMin     = 7.0;
ACME_acre_babbleGapMildRand    = 5.0;
ACME_acre_babbleGapSevereMin   = 1.6;
ACME_acre_babbleGapSevereRand  = 1.8;
ACME_acre_babbleStartMildMin   = 0.55;
ACME_acre_babbleStartMildRand  = 0.85;
ACME_acre_babbleStartSevereMin = 0.18;
ACME_acre_babbleStartSevereRand= 0.40;

ACME_darkness_enable = true;

// Initialize ACRE speech state once ACRE has had time to finish its own startup. Phase 142 will not touch Babel at
// all while Obtundation is disabled. If the master is enabled and the mission has no Babel setup, ACME establishes
// its own Common baseline before registering the synthetic obtunded language.
if (hasInterface) then {
    [{ call ACME_fnc_acreBabbleInit; }, [], 5] call CBA_fnc_waitAndExecute;
};
