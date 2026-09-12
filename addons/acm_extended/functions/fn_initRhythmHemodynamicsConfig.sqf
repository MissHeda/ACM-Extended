// atrial-rhythm pain and obtundation episodes.
// these rhythms cause pain while the patient is awake, and it decays to none while they are unconscious. they
// can also drop the patient into a syncope-like obtundation episode. Rhythm-generated discomfort does not
// feed back into its own HR target; independent native pain and other physiological adjustments still do.
ACME_rhythm_painRVR            = 0.50;  // AFib-RVR: moderate pain while conscious
ACME_rhythm_painAtrialTach     = 0.35;  // atrial tach: mild-moderate
ACME_rhythm_painAFib           = 0.35;  // controlled AFib: mild-moderate
ACME_rhythm_painSVT            = 0.45;  // SVT: moderate (palpitations)
ACME_rhythm_painStepPerSec     = 0.12;  // pain ramp/decay rate (per second)
ACME_rhythm_obtundChancePerTick = 0.015;  // per 0.5 s tick chance to enter an obtundation episode
ACME_rhythm_obtundMinSec       = 12;  // episode duration floor
ACME_rhythm_obtundMaxSec       = 30;  // episode duration ceiling
// per-rhythm hemodynamic instability, as a MAP drop in mmhg, where a negative value is hypotension. it cascades
// into NIBP, capillary refill, the obtunded band and CPP through the getbloodpressure offset.
ACME_rhythm_bpDropRVR          = -28;  // AFib-RVR: hemodynamically unstable, poorly perfusing
ACME_rhythm_bpDropAtrialTach   = -12;  // atrial tach: mildly unstable
ACME_rhythm_bpDropTorsades     = -30;  // torsades: near-arrest perfusion
ACME_rhythm_bpDropAFib         = 0;  // controlled AFib: rate-controlled, perfuses fine
ACME_rhythm_bpDropSVT          = -18;  // SVT: symptomatic / cardiovertible

// synchronized cardioversion, the LifePak SYNC key.
// these are the custom rhythms that perfuse. ACM's critical-vitals watchdog arrests anything that is not sinus
// or vt, and our rhythms all live in ACM's own rhythmstate variable. without this list an injured patient in
// any of them gets arrested into vf on a timer whatever the medic does. torsades, 102, is absent on purpose. it
// is a lethal ventricular rhythm and it should degenerate. it proxies to ACM as PVT. see ACME_rhythm_acmProxy
// below.
ACME_rhythm_perfusingCustom = [100, 101, 103, 104];

// what each custom rhythm looks like to ACM. anything not listed proxies as sinus, 0, which is correct for a
// perfusing supraventricular rhythm. torsades proxies as PVT, 3, because it is ventricular, shockable and
// lethal. if it proxied as sinus it would become harmless, and a defibrillation would asystole the patient.
// see fn_rhythmset. this is the piece that lets us stop lying to ACM without losing anything.
ACME_rhythm_acmProxy = [[102, 3]];

// Electrical monitor-rate contract. PEA is normally near 100 BPM, with a minority brady-PEA phenotype. The chosen
// PEA rate is seeded once per arrest episode on the patient owner, then networked so every monitor hears/draws it.
ACME_peaBradyChance        = 0.25;
ACME_peaNormalMinHR        = 90;
ACME_peaNormalModeHR       = 100;
ACME_peaNormalMaxHR        = 110;
ACME_peaBradyMinHR         = 35;
ACME_peaBradyModeHR        = 45;
ACME_peaBradyMaxHR         = 58;
ACME_rhythm_vfElectricalHR  = 170;
ACME_rhythm_pvtElectricalHR = 220;
