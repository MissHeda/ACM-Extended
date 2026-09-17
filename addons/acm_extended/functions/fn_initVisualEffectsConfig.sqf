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
// Ketamine visual thresholds are fractions of ACME's induction-equivalent ketamine load, NOT raw ACM medication
// count. This keeps low analgesic doses subtle while preserving a continuous path into Moderate/Severe dissociation.
ACME_visualFx_ketamineStart = 0.10;
ACME_visualFx_ketamineFull = 0.82;
// The water cue starts earlier than the heavier blur/chromatic profile but still uses induction-normalized load.
ACME_visualFx_ketamineWetStart = 0.025;
ACME_visualFx_ketamineWetFull = 0.82;
ACME_visualFx_ketamineWetRiseSec = 5.0;   // slower smooth onset; no initial strong-wave burst
ACME_visualFx_ketamineWetFallSec = 5.5;   // gentle recovery/washout
ACME_visualFx_ketamineGeneralRiseSec = 4.0; // blur/chromatic dissociation follows rather than snapping on
ACME_visualFx_ketamineGeneralFallSec = 4.5;
ACME_visualFx_tunnelStart = 0.50; // same severe-range onset used by the ACM-style radial tunnel profile
