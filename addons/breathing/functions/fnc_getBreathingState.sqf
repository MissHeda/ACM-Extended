// an ACME override of ACM_breathing_fnc_getBreathingState, installed at compile time through CfgFunctions, in class
// ACME_overwrite_breathing in config.cpp. ACM compiles its breathing functions final, so this must replace rather
// than wrap.
// it reproduces ACM's pneumo, hemothorax, hardcore-ptx and cbrn-exposure breathing-state model verbatim, with full
// variable names and no macros, since this file is compiled in the tag context of the ACME addon, then applies a
// graded over-resuscitation pulmonary-edema penalty on top.
// on why this and not the old SpO2 cap: fluid overload should knock down breathing effectiveness the same way a
// pneumo or hemothorax does, because pulmonary edema floods the alveoli and degrades gas exchange, and then ACM's
// own oxygen sim carries SpO2 down from there, gradually, on its own curve. that is more correct, and feels right
// in game, compared with artificially pinning SpO2 to a floor.
// the penalty is multiplicative, exactly like the hemothorax term above it, scales from nothing at the onset
// threshold to ACME_edema_breathPenaltyMax at the overload cap, and has its own coefficient so it can be tuned
// independently of every other breathing insult.
params ["_patient"];

private _state = 1;

private _HTXFluid  = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];
private _PTXState  = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _TPTXState = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _hardcorePTX = _patient getVariable ["ACM_breathing_Hardcore_Pneumothorax", false];

if (_HTXFluid > 0.3) then {
    _state = 1 - (0.9 * (_HTXFluid / 1.5));
};

if (_TPTXState) then {
    _state = 0.1;
} else {
    _state = _state - (_PTXState / 10);
};

if (_hardcorePTX) then {
    _state = _state min ([0.8, 0.95] select (_patient getVariable ["ace_medical_inCardiacArrest", false]));
};

// cbrn and cold-exposure breathing ability, from ACM get_exposure_breathingstate into
// ACM_CBRN_BreathingAbility_State.
private _exposureBreathingState = _patient getVariable ["ACM_CBRN_BreathingAbility_State", 1];
if (_exposureBreathingState < 1) then {
    _state = _state * _exposureBreathingState;
};

// ACME: over-resuscitation pulmonary edema gives a graded gas-exchange penalty.
private _ov  = _patient getVariable ["ACM_circulation_Overload_Volume", 0];
private _thr = missionNamespace getVariable ["ACME_edema_threshold", 0.5];
if (_ov > _thr) then {
    private _cap = missionNamespace getVariable ["ACME_edema_overloadCap", 1.8];
    private _sev = linearConversion [_thr, _cap, _ov, 0, 1, true];  // 0 at onset, 1 at the overload cap.
    private _pen = _sev * (missionNamespace getVariable ["ACME_edema_breathPenaltyMax", 0.35]);
    _state = _state * (1 - _pen);
};

_state
