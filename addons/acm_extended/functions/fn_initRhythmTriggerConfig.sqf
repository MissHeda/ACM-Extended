// custom-rhythm auto-triggers.
// hemorrhage alone must stay sinus tachycardia. SVT and atrial tach should come from a catecholamine surge:
// push-dose epi that stacks, a distal peripheral epi or norepi effect, or a hypertensive spike from a distal
// medicated line. the circulation handler builds a composite pressor-surge score and needs it to stay high
// before it induces a rhythm.
ACME_rhythmPressorSurgeEnabled = true;
ACME_rhythmPressorSurgeATThreshold = 18;  // composite mmhg-equivalent surge score needed for atrial tach
ACME_rhythmPressorSurgeSVTThreshold = 35;  // stronger surge promotes to SVT
ACME_rhythmPressorSurgeSustainSec = 6;  // sustained surge before rhythm induction
ACME_rhythmPressorSurgeClearFactor = 0.55;  // reset the sustain gate once the surge falls below the threshold times this.
ACME_rhythmPressorSurgeRefractorySec = 90;  // no repeated auto-induction spam after one surge rhythm
ACME_rhythmPressorSurgeMinHR = 115;  // must be physiologically tachy already
ACME_rhythmPressorSurgeMaxHR = 220;  // below ACM's native fatal hr line; ACM owns >220 vt/PVT
ACME_rhythmPressorSurgeScoreCap = 60;  // B21: arrhythmia burden is not capped by the 25 mmHg pressor-MAP ceiling; allows a severe epi drip to progress from A-tach to SVT.
ACME_rhythm_epiDripChance = 1;  // legacy compat. the current surge gate is deterministic once sustained.
ACME_rhythm_epiSVTSplit   = 0.5;  // legacy compat only
// AFib-RVR comes from severe hypothermia, rolled in fn_hypothermiatick.
ACME_rhythm_afibHypoTempC  = 32;  // core temp (c) at/below which AFib-RVR can be thrown
ACME_rhythm_afibHypoChance = 0.15;  // per cooling-tick chance once at/below that temp
// controlled AFib comes from AFib-RVR plus an esmolol drip, scheduled in fn_registerbagmedication.
ACME_rhythm_esmololControlSec = 25;  // onset delay in s before esmolol rate-controls AFib-RVR into controlled AFib.
// torsades comes from cumulative amiodarone over the ceiling, profound hypocalcemia or raised ICP, rolled in
// fn_circhandle.
ACME_rhythm_torsadesCaThresh      = 0.62;  // the ionized ca at or below which torsades can be thrown. it is probabilistic and moderate.
ACME_rhythm_amioControlEffect     = 0.40;  // the ACM amiodarone effect at which it rate-controls AFib-RVR or breaks atrial tach.
ACME_rhythm_amioSVTEffect         = 0.70;  // a higher bar for SVT, because adenosine is first line and amiodarone is a later choice.
ACME_rhythm_amioCeilingMg         = 2200;  // cumulative amiodarone in mg over which torsades can be thrown. it is probabilistic.
ACME_rhythm_torsadesChancePerTick = 0.0004;  // per circ-tick, 0.25 s, chance while a moderate torsades substrate is present. it is rare.
ACME_rhythm_torsadesChanceSevere   = 0.0012;  // per circ-tick chance while a severe substrate is present. it is still probabilistic and never guaranteed.
ACME_rhythm_torsadesRefractorySec = 120;  // legacy, kept for compat. mag now opens a suppression window instead.
ACME_rhythm_defibTorsadesRefractorySec = 8;  // after a defibrillation converts torsades, a brief organized window before it can recur. it depends on the cause.
// deterministic bad-enough triggers, with recurrence until magnesium.
// past these severe thresholds torsades fires reliably on every eligible tick, rather than probabilistically,
// so profound hypocalcemia or a herniating ICP always throws torsades. once thrown it recurs. a shock buys only
// the short defib window above, after which the severe cause re-induces it. a push of magnesium opens a
// suppression window, ACME_rhythm_magSuppressSec, during which no new torsades fires whatever the cause. push
// mag, and fix the ca or drop the ICP, to stop the loop. mag is temporizing. if the window lapses while the
// cause is still severe, it can recur, so push again. set magsuppresssec very high to make mag effectively
// permanent.
ACME_rhythm_torsadesCaSevere      = 0.57;  // the ionized ca at or below which torsades fires deterministically. the ionizedca floor is 0.55, so maximum hypocalcemia lands in this band.
ACME_rhythm_torsadesICPThresh     = 24;  // the ICP in mmhg at or above which torsades can be thrown. it is probabilistic and moderate.
ACME_rhythm_torsadesICPSevere     = 30;  // the ICP in mmhg at or above which torsades fires deterministically. this is herniation territory.
ACME_rhythm_magSuppressSec        = 300;  // after magnesium, the window in s during which torsades cannot re-fire.
// the other custom rhythms stay debug-induced for now. see the readme for the recommended triggers.
