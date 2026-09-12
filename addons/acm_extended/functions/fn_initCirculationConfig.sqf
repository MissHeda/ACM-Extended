/*
 * Phase 20 subsystem initialization: Circulation, acid-base, hypothermia and custom-rhythm tunables.
 *
 * This is a behavior-preserving extraction from ACME_fnc_postInit. Keep runtime
 * event/PFH ownership in postInit or the owning subsystem; this helper only establishes
 * startup state and tunables in the same order as before.
 */

// circulation, shock and push-dose epi. see fn_circhandle.
ACME_circ_activePatients = [];
// ACME_circ_shockFloorMAP moved to CBA, under circulation.
ACME_circ_shockInitialSeverity = 0.6;  // severity on induction (immediately peri-arrest)
ACME_circ_shockProgressPerSec = 0.006;  // untreated crash creep -> arrest in ~1 min
// shock heart-rate arc
ACME_circ_shockTachyPeak = 120;  // compensatory tachycardia peak (~severity 0.5)
ACME_circ_shockBradyFloor = 32;  // decompensated bradycardia at full severity. it is below ACM's hr 40 arrest line.
ACME_circ_supportChronotropy = 0.8;  // bpm of hr rescue per mmhg of pressor/push-dose support
ACME_circ_hrStepPerCall = 2;  // max bpm change per 0.25s tick (bounded nudge)
// acidosis into catecholamine refractoriness. this is the sustained-shock death spiral, and it is capped.
ACME_circ_acidosisMAPThreshold = 55;  // effective MAP below which acidosis accrues
ACME_circ_acidosisPerSec = 0.004;  // accrual rate while hypoperfused. it was 0.015, and about 4.2 min now reaches the cap, which makes it a slow background threat rather than a fast tick.
ACME_circ_acidosisRecoverPerSec = 0.01;  // recovery rate once MAP restored
// respiratory acidosis is CO2 retention from inadequate ventilation. this is the accrual rate at full deficit,
// which means apnea, a fully obstructed airway or an untreated tension pneumothorax. at 0.02/s it exceeds the
// 0.01 recovery, so a deficit past about 0.5 outpaces recovery and builds, while mild under-breathing decays.
// a fix to the airway or the breathing zeroes the deficit.
ACME_circ_respAcidosisPerSec = 0.006;
ACME_circ_respAcidosisRecoverPerSec = 0.012;  // respiratory acidosis recovery when ventilation is corrected
// internal PaCO2 model. PaCO2 is the retained CO2 and drives respiratory acidosis. EtCO2 is the exhaled and
// displayed estimate only.
ACME_circ_paCO2Enabled = true;
ACME_circ_paCO2Normal = 40;
ACME_circ_paCO2Max = 95;
ACME_circ_paCO2RespAcidStart = 45;
ACME_circ_paCO2RespAcidFull = 80;
ACME_circ_paCO2RisePerSec = 0.09;  // max hypoventilation rise, mmhg/sec
ACME_circ_paCO2ApneaBonusPerSec = 0.05;  // extra rise during apnea/no exhalation
ACME_circ_paCO2ClearPerSec = 0.18;  // clearance toward normal with adequate ventilation
ACME_circ_paCO2ExhaleMinVentFrac = 0.08;
// arrest is forced apnea with no perfusion unless a medic is using a BVM. this keeps acidosis and PaCO2
// building during cardiac arrest, instead of freezing while ACM's stale vitals still show a rate and a bp.
ACME_circ_arrestForcesAcidosis = true;
ACME_circ_bvmVentFrac = 0.75;  // effective ventilation fraction while a medic is actively bagging during arrest.
ACME_circ_acidosisMaxBlunt = 0.45;  // max fraction of support lost at full total acidosis
// acidosis also impairs the clotting cascade, which completes the acid leg of the lethal triad. the coag
// multiplier ramps from 1, no effect, at or below the threshold, up to maxmult at full acidosis. it multiplies
// onto the calcium and hypothermia coag mult that the bleed override reads. at a full triad the three legs
// compound, so 1.4 by 1.6 by 1.3 gives about 2.9 times the bleeding. each leg needs extreme derangement.
ACME_acidosis_coagThreshold = 0.3;  // acidosis below this adds no coagulopathy (clotting holds)
ACME_acidosis_coagMaxMult = 1.3;  // bleed multiplier at full acidosis (x calcium x hypothermia)
// plasma-lyte a buffer. this is the acidosis, on a 0 to 1 scale, reversed per ml of plasma-lyte that
// transfuses. at 0.0008/ml a full 1000 ml bag buffers about 0.8 of the acidosis scale, which is near-complete
// correction.
ACME_plasmaLyte_acidosisPerMl = 0.0008;
// normal saline chloride load. the cumulative delivered ns creates a persistent metabolic acidosis floor. it
// starts after 500 ml and rises nonlinearly to its maximum at 3000 ml.
ACME_salineAcidosis_enabled = true;
ACME_salineAcidosis_startMl = 500;
ACME_salineAcidosis_fullMl = 3000;
ACME_salineAcidosis_max = 0.65;
ACME_salineAcidosis_exponent = 2.0;
// debug and readout names. saline uses a quadratic volume curve. the shock, respiratory and CPP sources are
// time-integrated.
ACME_acidosis_debugPrecision = 3;
// hypothermia, the third leg of the lethal triad. the core temp is in degrees c.
ACME_hypo_coagStartTemp = 35;  // coagulopathy begins below this temp
ACME_hypo_coagFullTemp = 32;  // ...and is maximal at/below this temp
ACME_hypo_coagMaxMult = 1.6;  // bleed-rate multiplier at full hypothermic coagulopathy
ACME_hypo_bluntStartTemp = 34;  // pressor blunting begins below this temp
ACME_hypo_bluntFullTemp = 30;  // ...and is maximal at/below this temp
ACME_hypo_maxBlunt = 0.5;  // max fraction of pressor/push-dose support lost when cold
// hypothermia worsens acidosis indirectly. it amplifies the shock and lactic accrual and slows the metabolic
// recovery. it does not create acidosis by itself.
ACME_hypo_acidStartTemp = 35;  // metabolic acidosis penalty begins below this temp
ACME_hypo_acidFullTemp = 30;  // maximum acidosis penalty at/below this temp
ACME_hypo_acidMaxGainMult = 1.5;  // max multiplier on shock/metabolic acidosis accrual
ACME_hypo_acidMinRecoveryMult = 0.25;  // max hypothermia recovery penalty (25% normal recovery)
// low CPP from TBI or ICP contributes only when the cerebral perfusion is genuinely poor.
ACME_tbi_cppAcidosisEnabled = true;
ACME_tbi_cppAcidosisFullCPP = 30;  // CPP at/below which the TBI metabolic acid drive is maximal
ACME_tbi_cppAcidosisPerSec = 0.0015;  // small secondary metabolic accrual at full low-CPP deficit
ACME_hypo_bradyStartTemp = 33;  // bradycardia begins below this temp
ACME_hypo_bradyFullTemp = 28;  // ...and reaches the floor hr at/below this temp
ACME_hypo_bradyFloorHR = 34;  // cold hr floor (drives ACM's hr<40 arrest path)
ACME_hypo_bradyRatePerSec = 6;  // bpm/s the rate is pulled toward the cold target
ACME_hypo_debugStages = 1;  // (debug toggle cycles 37->34->31->28->clear)
// custom cardiac rhythms, the display and the rate. these perfuse and have no hemodynamic coupling yet.
ACME_rhythm_tickDt = 0.5;  // sustain tick cadence (s). keep == the pfh interval below
ACME_rhythm_hrRatePerSec = 12;  // bpm/s the rate is driven toward target
ACME_rhythm_ekgPeriodScale = 2.22;  // ekg beat-period scale, in samples per ACM gap-unit. raise it for a faster QRS.
ACME_rhythm_afibHR = 165;  // AFib-RVR target rate
ACME_rhythm_afibControlledHR = 80;  // AFib (controlled ventricular response) target rate
ACME_rhythm_atHR = 185;  // atrial tachycardia target rate
ACME_rhythm_torsadesHR = 210;  // torsades target rate (kept < ACM's 220 hr arrest line)
ACME_rhythm_svtHR = 190;  // SVT target rate (narrow-complex, regular, cardiovertible)
ACME_rhythm_torsadesTwistDeg = 26;  // (legacy, unused by the spindle rewrite)
ACME_rhythm_torsadesTwistBeats = 7;  // torsades. complexes per half-twist, node to node. lower gives a faster twist.
ACME_rhythm_torsadesFloor = 0.12;  // torsades. minimum complex amplitude at a twist node. 0 collapses to baseline.
ACME_rhythm_torsadesEntryMinSec = 6;  // entry/degeneration window. the actual transition duration is this OR the sweep count below, whichever is longer.
ACME_rhythm_torsadesEntrySweeps = 3;  // number of monitor sweeps the organized entry rhythm is allowed to degrade across.
ACME_rhythm_torsadesEntryLeadIn = 0.35;  // fraction of one rendered buffer used to bias later visible beats deeper into torsades.
ACME_rhythm_torsadesBeatNoise = 5;  // jaggedness/noise applied to the polymorphic complexes.
ACME_monitorRhythmSwitchMaxWait = 0.18; // B67: rhythm changes may splice into the active sweep; only defer briefly to avoid cutting the middle of a QRS.
