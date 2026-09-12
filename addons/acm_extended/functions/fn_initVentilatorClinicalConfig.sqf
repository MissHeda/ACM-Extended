/*
 * Phase 22 subsystem initialization: Ventilator trigger, dyssynchrony, alarms, circuit, sedation and boot-audio tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// ventilator alarm thresholds. the ALERTS screen sets the per-patient ones and these are the engine
// defaults.
// trigger sensitivity, in the units of the real device: an inspiratory pressure threshold. the sparrow ranges
// from -0.25 cmH2O, feather-light, to -10 cmH2O, where only a strong effort triggers, plus OFF. use 0 for OFF,
// which disables patient triggering and leaves the machine purely mandatory. a paralyzed casualty never
// triggers whatever this value is.
ACME_vent_trigSensCmH2O = -2;  // default only; B18 stores the active trigger threshold per allocated ventilator.
// B18 patient-ventilator interaction. These are deliberately restrained: dyssynchrony first degrades ventilation,
// then gives a modest sympathetic response over tens of seconds. There is no direct VF/arrest consequence.
ACME_vent_dyssyncRiseSec = 18;
ACME_vent_dyssyncFallSec = 9;
ACME_vent_fightStressRiseSec = 45;
ACME_vent_fightStressFallSec = 14;
ACME_vent_fightHRMax = 18;          // additive bpm target at maximal sustained dyssynchrony.
ACME_vent_fightResistMax = 9;       // additive SVR points at maximal sustained dyssynchrony.
ACME_vent_fightO2PenaltyMax = 6;    // maximum extra target-saturation points at severe, poorly ventilated dyssynchrony.
// alarm settle window. this is the seconds after the machine starts driving before the minute-volume alarms
// can fire. a vent that was just connected has not completed a breath cycle, so its measured mv is not yet a
// real number. an alarm on it means every startup opens with a warning on perfectly good settings.
ACME_vent_alarmSettleSec = 12;

// ROSC reversible-cause gate, for the hardcore rhythms only. these are the thresholds for the causes ACM does
// not model. ACM's own four, hypoxia, tension pneumothorax, tension hemothorax and class 4 hemorrhage, are
// untouched and not duplicated here.
ACME_rosc_hypothermiaFloorC = 30;  // below this a cold myocardium will not hold a rhythm. rewarm first.
ACME_rosc_paCO2BlockMmHg    = 85;  // severe respiratory acidosis. ventilate the CO2 down before you expect ROSC.
ACME_vent_alarmLowVteFrac = 0.70;  // VTe below this fraction of set vt -> LOW EXHALED VOLUME
ACME_vent_alarmLowMvAdequacy = 0.75;
ACME_vent_alarmHighMvAdequacy = 1.35;
// alarm severity tables. the audible pattern in fn_ventalarmtick and the on-screen color and header, from
// fn_ventalarmwindow through fn_ventalarmseverity, both read these, so the buzzer and the screen can never
// disagree.
// HIGH, red, "ALARM": the patient is not ventilated, or is injured, right now.
// med, yellow, "WARNING": the ventilation is going wrong. it is dangerous and not instantly fatal.
// everything else is LOW, gray, "ALERT", and informational.
ACME_vent_alarmHigh = ["CIRCUIT DISCONNECT", "APNEA", "HIGH AIRWAY PRESSURE", "GAS TRAPPING", "NO SPONT. EFFORT"];
ACME_vent_alarmMed  = ["LOW MINUTE VOLUME", "HIGH MINUTE VOLUME", "LOW EXHALED VOLUME", "HIGH RESP RATE", "LOW RESP RATE"];
ACME_vent_alarmAutoPeep = 4;  // auto-PEEP (cmH2O) at which GAS TRAPPING alarms
ACME_vent_manualBreathMinGap = 1.5;  // refractory between manual breaths
ACME_vent_manualBreathWindow = 12;  // how long hand-breathing keeps counting as the patient's rr
ACME_vent_leash = 2.5;  // m the operating medic can move from the patient before the circuit pulls off.
// sedation-assisted intubation. this is the minimum weighted ketamine dose on board for a medic to
// laryngoscope a conscious patient without a paralytic. about 0.5 is an induction-size push. see the dose scale
// in fn_ketamineonboard. below this an awake casualty cannot be intubated, because they would gag or
// laryngospasm, so push ketamine first.
ACME_vent_saiKetamineDose = 0.8; // B14 induction-normalized procedural tolerance.
                                    // fn_ventleashtick severs the tie. the machine stops driving and forgets the patient.
ACME_vent_startupSndLen  = 2.324;  // ventilator_startup_sfx length in s, for the startup to loop handover timing.
// power-on jingle. it plays over the white splash with the sparrow mark. the splash holds for the delay plus
// the clip plus the gap, so the screen follows the audio instead of the audio being cut to fit the screen.
// re-cut the clip and only the length below needs a change.
ACME_vent_blackoutSec    = 0.45;  // dead-black panel on open, before the screen wakes. this is the power-button beat.
ACME_vent_jingleDelaySec = 0.5;  // beat AFTER the splash appears before the chime starts
ACME_vent_jingleSndLen   = 1.675;  // vent_jingle_sfx length (s). must match the file.
ACME_vent_bootGapSec     = 0.25;  // gap after the jingle before the self-test takes over
ACME_vent_shutdownSndLen = 2.324;  // ventilator_shutdown_sfx length in s, for the shutdown cooldown.
ACME_vent_runningSndLen  = 5.721;  // ventilator_running_sfx length (s). paces the self-test ring.
