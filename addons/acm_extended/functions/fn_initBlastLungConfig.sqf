/*
 * Phase 22 subsystem initialization: Blast-lung pacing, treatment ladder and ARDS progression tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// blast lung, a primary blast injury from explosive overpressure.
// it is rare and circumstantial by design. only genuine blast or explosive damage can cause it, it needs a
// meaningful hit to the torso so the overpressure crosses the chest, and it is then a roll. this is the injury
// that creates a real need for the ventilator. see fn_blastlungtick.
// fn_blastlungtick reads the pacing tunables. the gas-exchange penalty ramps in across effectrampsecs from the
// moment of injury, and even a maximal blast lung never drops the breathing ability below abilityfloor.
// together these make an untreated blast lung a slide into hypoxia across minutes, which gives time to secure
// the airway and ventilate, instead of the near-instant hypoxic arrest it used to be.
ACME_blastLung_effectRampSecs = 150;  // ~2.5 min for the gas-exchange penalty to reach full effect
ACME_blastLung_abilityFloor   = 0.45;  // lowest breathing-ability multiplier a maximal blast lung produces.

// graded treatment effectiveness and ARDS progression.
// blast lung is no longer correct vent or die. it responds to a ladder of interventions, each with its own heal
// and worsen rate, and it progresses to ARDS if a medic leaves it untreated or treats it ineffectively. the
// ventilator on the right settings is the most effective path and not the only one, and supplemental o2 beats a
// bare BVM by a wide margin.
// tier                                             rate on the 0 to 1 severity   meaning
// correct vent, pc, adequate mv, FiO2, safe PIP    heal strong                   the right answer
// vent, wrong, vc or high PIP into a stiff lung    worsen by baroworsenmult       actively destructive
// BVM with supplemental o2                         heal mild                     holds the line, recovers slowly
// BVM alone, no o2                                 neutral to slight worsen      buys time, does not fix
// supplemental o2 passive, no positive pressure    slight heal on mild only      a walking wounded can ride it out
// nothing                                          worsen toward ARDS            the slide
ACME_blastLung_healVentPerSec   = 0.0016;  // correct mechanical ventilation: strongest recovery
ACME_blastLung_healBvmO2PerSec  = 0.0008;  // BVM with oxygen. this is a real, slower recovery, because positive pressure and o2 recruit.
ACME_blastLung_healO2PerSec     = 0.00035;  // passive supplemental o2, for a mild blast lung only. it is a slow ride-it-out recovery.
ACME_blastLung_worsenBasePerSec = 0.0008;  // untreated slide
ACME_blastLung_worsenBvmPerSec  = 0.0003;  // bare BVM (no o2): slowed slide, still losing ground
ACME_blastLung_baroWorsenMult   = 3;  // vc or high PIP into a stiff lung. barotrauma multiplies the worsening.
ACME_blastLung_mildThreshold    = 0.30;  // below this severity a blast lung is mild. it can plateau or self-resolve on o2 with no positive pressure.
ACME_blastLung_o2PlateauMax     = 0.45;  // passive o2 can hold a blast lung from worsening up to this severity, and heals it below mildthreshold only.
// ARDS. a sustained severe blast lung, or repeated ineffective treatment, converts to ARDS, a refractory
// stiff-lung state. it is far harder to reverse, because it heals at a fraction of the rate and worsens faster.
// it will not resolve without sustained correct ventilation, and it leaves a permanent floor once entered, the
// same way herniation does, because the lung is scarred. this is the actual damage endpoint of an untreated
// blast lung.
ACME_blastLung_ardsEnterSev     = 0.85;  // the severity at or above which, sustained, a blast lung converts to ARDS.
ACME_blastLung_ardsEnterSecs    = 60;  // seconds held at/above ardsentersev before ARDS latches
ACME_blastLung_ardsHealMult     = 0.35;  // ARDS heals at 35 percent of the normal rate. even correct ventilation is a long haul.
ACME_blastLung_ardsWorsenMult   = 1.5;  // ARDS worsens faster when unsupported
ACME_blastLung_ardsSevFloor     = 0.35;  // once ARDS latches, severity can never recover below this, because the lung is scarred. it needs evac for definitive care.
ACME_blastLung_ardsFloorMult    = 0.8;  // ARDS lowers the breathing-ability floor to 80 percent. this is refractory hypoxemia, so the achievable SpO2 is lower even with support.
ACME_blastLung_ardsSpO2Drop     = 8;  // ARDS drops the SpO2 ceiling by this much in cbrn mode. this is refractory hypoxemia.
