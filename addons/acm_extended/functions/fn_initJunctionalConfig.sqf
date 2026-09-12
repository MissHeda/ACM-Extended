// junctional wounds: the auto-spawn and the bleed and pain tuning.
// the chance is high off a medium or large velocity wound, and low off a large avulsion on the chest, arms or
// legs.
ACME_junctionalChanceVelocity = 0.60;  // medium-large VelocityWound -> junctional (high)
ACME_junctionalChanceAvulsion = 0.15;  // large avulsion -> junctional (low)
ACME_junctionalBleedNorm      = 0.10;  // B31: custom drain per junction; native wounds still bleed separately. Was 0.35.
ACME_junctionalDPControl      = 0.15;  // direct pressure multiplier on an open junctional part. 0.15 controls about 85 percent, because dp is the first-line control on the worst wound.
ACME_junctionalPackControl    = 0.0;  // bleed multiplier while a medic packs combat gauze. the hands and gauze tamponade the bleed fully during the pack, and it resumes to the 50 percent packed hold when the packing finishes.
ACME_junctionalGauzeControl   = 0.50;  // finished combat-gauze packing, not yet wrapped. the bleed multiplier is 0.50, which is 50 percent control. it holds at this level until a pressure bandage wraps it, with no work-loose falloff.
ACME_junctionalGauzeDPControl = 0.00;  // combat gauze plus direct pressure held on top. 0.00 adds the other 50 percent of control, so the bleed stops fully while held. a lift of the dp returns it to the 50 percent gauze level.
ACME_junctionalPackedOoze     = 0.10;  // legacy, retained for back-compat. ACME_junctionalGauzeControl supersedes it for the packed state.
ACME_junctionalPackFalloff    = 75;  // legacy work-loose timer. it no longer applies to packed gauze, because the gauze holds at 50 percent until a wrap.
ACME_junctionalPackPain       = 0.20;  // pain added on packing a conscious casualty (moderate)
ACME_junctionalWrapPain       = 0.20;  // pain added when a medic wraps a conscious casualty. the pack and wrap together stay below the tourniquet max.

// XStat rebleed. see fn_junctionalstartbleed.
ACME_xstatRampTime       = 12;  // seating: bleed ramps full -> 0 over this many seconds
ACME_xstatDwellTime      = 7200;  // the bolus holds for this long (2 h) before it starts to fail
ACME_xstatRebleedTime    = 120;  // once it fails, the rebleed grows from a trickle to full across 2 min.
ACME_xstatRebleedMaxFrac = 0.5;  // ...and full = at most half the original bleed. never more.
