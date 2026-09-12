/*
 * Phase 23 runtime ownership: Circulation, saline-acidosis and automatic-BP runtime ticks.
 *
 * Extracted intact from ACME_fnc_postInit. The helper is invoked synchronously at the
 * original registration point so CBA handler/PFH order is unchanged.
 */

[{call ACME_fnc_salineAcidosisTrack}, 0.25, []] call CBA_fnc_addPerFrameHandler;
[{call ACME_fnc_circHandle}, 0.25, []] call CBA_fnc_addPerFrameHandler;
[{call ACME_fnc_autoBPTick}, 1, []] call CBA_fnc_addPerFrameHandler;
