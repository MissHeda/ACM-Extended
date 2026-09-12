// rhythm threshold guard. do not let a critical hr stay displayed as plain sinus.
ACME_rhythmThresholdsEnabled = true;
ACME_hrHardMax = 260;
ACME_rhythmUseACMNativeFatalThresholds = true;
ACME_rhythmACMFatalHighHR = 220;  // exact ACM high-hr fatal threshold: strict hr > 220
ACME_rhythmACMFatalLowHR = 40;  // exact ACM low-hr fatal threshold: strict hr < 40
ACME_rhythmACMHighClearHR = 200;  // stock ACM clears vt once hr is under 200. we need this to be sustained.
ACME_rhythmACMLowClearHR = 45;
ACME_rhythmNativeHoldMinSec = 999999;  // native vt/vf/asystole do not self-clear from rate wobble
ACME_rhythmNativeClearSustainSec = 999999;
ACME_rhythmNativeFallbackSec = 1.25;  // legacy diagnostic timing only; B67 removes ACME's independent native fatal-rate arrest path.
ACME_rhythmNativeHighHoldHR = 222;  // sustained vt floor while native vt latch is active
ACME_rhythmNativeHighHRFloorSec = 999999;
ACME_rhythmNativeVTRecoverHR = 200;  // B21: only threshold-forced perfusing VT may clear after the rate has safely recovered below this.
ACME_rhythmNativeVTRecoverSec = 6;  // B21: sustained recovery required before clearing a threshold-forced VT latch.
ACME_rhythmUseACMFatalEventMirror = false;  // ACM core owns the actual fatal/arrest event
ACME_rhythmNativePersistentEnabled = true;
ACME_rhythmNativeShockGraceSec = 10;
ACME_rhythmAutoSVTFromRateEnabled = false;  // hemorrhagic sinus tachycardia should stay sinus tachycardia
ACME_rhythmCustomSVTHR = 190;
ACME_rhythmCustomSVTSustainSec = 8;
ACME_rhythmCriticalHighHR = 220;
ACME_rhythmCriticalSVTHR = 190;
ACME_rhythmCriticalLowHR = 40;
ACME_rhythmCriticalSustainSec = 4;
[{call ACME_fnc_rhythmThresholdTick}, 0.5, []] call CBA_fnc_addPerFrameHandler;
