// hardcore.
// hardcore.
// this resolves the effective hardcore setting per system and applies the difficulty knobs of each one. it
// moved into ACME_fnc_applyHardcore so it can be re-applied live from the CBA change handlers. it previously
// ran once at postinit, so a tick of a hardcore box mid-mission did nothing and an untick never restored the
// baseline.
ACME_hcReady = true;
call ACME_fnc_applyHardcore;
