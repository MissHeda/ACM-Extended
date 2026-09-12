/*
 * Phase 22 subsystem initialization: Narc Box body-map sizing, access and IM presentation tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// narc box body map.
// body_background.paa is a square 2048 canvas, and the drawn body fills 88.3 percent of its height. keepaspect
// fits the canvas, so the control must be square and sized from that fill fraction, or the body comes out
// small.
ACME_SK_BodyHeightFrac = 0.72;  // visible body, as a share of screen height
ACME_SK_BodyFillV      = 0.883;  // measured: how much of the canvas is body, vertically
ACME_SK_AccessColor    = [0.200, 0.596, 0.200, 1];  // ACM's own iv green, sampled from their medical menu
ACME_SK_IMColor        = [0.28, 0.60, 1.00, 0.42];  // the im limb aura
ACME_SK_SiteHitScale   = 0.46;  // vascular hotspot size, as a share of ACM's site rect
