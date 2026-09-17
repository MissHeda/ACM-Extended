/* Centralized local perception model. Debug variables and rendering stay client-local. */
ACME_visualFx_enabled = true;
ACME_visualFx_updateSec = 0.05;  // 20 Hz so HR-synchronous tunnel pulses remain legible even during tachycardia
ACME_visualFx_commitSec = 0.30;
ACME_visualFx_hypoxiaStart = 95;
ACME_visualFx_hypoxiaSevere = 72;
ACME_visualFx_mapStart = 70;
ACME_visualFx_mapSevere = 35;
ACME_visualFx_co2Start = 48;
ACME_visualFx_co2Severe = 85;
ACME_visualFx_ketamineStart = 0.35;
ACME_visualFx_ketamineFull = 1.15;
// WetDistortion begins earlier than the stronger dissociation/blur profile so ordinary therapeutic exposure is visible.
ACME_visualFx_ketamineWetStart = 0.05;
ACME_visualFx_ketamineWetFull = 1.15;
ACME_visualFx_ketamineWetRiseSec = 4.0;   // smooth wave onset; avoids the initial fast-wave burst
ACME_visualFx_ketamineWetFallSec = 5.0;   // slightly slower wave recovery/washout
ACME_visualFx_ketamineGeneralRiseSec = 3.5; // blur/chromatic dissociation also eases in instead of stepping on
ACME_visualFx_ketamineGeneralFallSec = 4.5;
ACME_visualFx_tunnelStart = 0.50; // same severe-range onset used by the ACM-style radial tunnel profile
