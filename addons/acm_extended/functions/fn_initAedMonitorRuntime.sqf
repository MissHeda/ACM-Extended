// AED beat clock. this is one authoritative hr-beep cadence, used both inside and outside the LifePak monitor.
// the old visible-column QRS beep lock is disabled, because it could double-fire or drift at a sweep wrap.
ACME_aedQrsBeepLockEnabled = false;
ACME_aedBeatClockEnabled = false;
ACME_aedBeatClockTickSec = 0.25;
ACME_aedMonitorQRSBeepEnabled = false;  // safety hotfix. there is no updatestep audio hook, so the ACM monitor draw path stays stock.
ACME_aedQrsNegThreshold = -28;
ACME_aedQrsPosThreshold = 18;
ACME_aedQrsCooldownFactor = 0.55;
ACME_aedQrsCooldownMin = 0.18;
ACME_aedQrsCooldownMax = 0.72;
ACME_monitorRhythmSwitchSafeAbs = 12;  // the ecg columns must be near-isoelectric before a visual rhythm swap.
ACME_monitorRhythmSwitchSafeSlope = 18;

// LifePak changing-rate conditioning. The same conditioned electrical rate is returned by getEKGHeartRate to the
// beep, displayed BPM and waveform generator. A stable rate is untouched; these values only limit how quickly a
// changing organized rhythm is allowed to retime its next complexes.
ACME_monitorHRRiseBpmPerSec = 36;
ACME_monitorHRFallBpmPerSec = 48;
ACME_monitorHRHardResetGap = 1.5;

if (missionNamespace getVariable ["ACME_aedBeatClockEnabled", false]) then { [{call ACME_fnc_aedBeatClockTick}, ACME_aedBeatClockTickSec, []] call CBA_fnc_addPerFrameHandler; };
