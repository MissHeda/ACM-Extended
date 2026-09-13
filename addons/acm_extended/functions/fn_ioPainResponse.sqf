/* B45 IO pain contract. Runs on the patient owner.
 *
 * placement: an IO insertion always establishes at least moderate pain, even if ACM's native lidocaine
 * suppression would otherwise reduce it below that floor.
 *
 * fluid: any fluid/medication pushed through an IO immediately drives raw pain to maximum severity. Consciousness
 * remains physiology-driven; the pain response itself does not hard-force a stable casualty unconscious.
 */
params ["_patient", ["_bodyPart", "body"], ["_mode", "fluid"]];
if (isNull _patient || {!alive _patient} || {!local _patient}) exitWith {};
_mode = toLowerANSI _mode;

private _isUncon = (_patient getVariable ["ACE_isUnconscious", false])
    || {_patient getVariable ["ace_medical_unconscious", false]};

if (_mode == "placement") exitWith {
    private _floor = missionNamespace getVariable ["ACME_ioInsertionMinPain", 0.35];
    private _current = (_patient getVariable ["ace_medical_pain", 0]) max 0;
    private _delta = (_floor - _current) max 0;
    if (_delta > 0.001 && {!isNil "ace_medical_fnc_adjustPainLevel"}) then {
        [_patient, _delta] call ace_medical_fnc_adjustPainLevel;
    };
    // Native ACM already plays the insertion reaction when its unsuppressed 0.31 pain lands. Only add a second
    // reaction when we had to make a meaningful top-up because native suppression dropped it below the floor.
    if (_delta > 0.05 && {!_isUncon} && {!isNil "ace_medical_feedback_fnc_playInjuredSound"}) then {
        [_patient, "hit"] call ace_medical_feedback_fnc_playInjuredSound;
    };
};

// IO flow is intentionally not suppressed by local lidocaine or systemic analgesia. The requested gameplay
// contract is max-severity marrow-pressure pain whenever fluid is actually pushed through the IO.
private _rawPain = (_patient getVariable ["ace_medical_pain", 0]) max 0;
if (_rawPain < 0.999) then {
    if (!isNil "ace_medical_fnc_adjustPainLevel") then {[_patient, 1] call ace_medical_fnc_adjustPainLevel;};
    if ((_patient getVariable ["ace_medical_pain", 0]) < 0.999) then {
        [_patient, [["pain", 1, true]]] call ACM_core_fnc_setAceMedicalState;
    };
};

// IO flow remains maximally painful, but pain alone no longer hard-forces a medically stable casualty unconscious.
// ACE/ACM physiology owns consciousness from here, so shock, hypoxia, TBI, sedation and arrest can still knock them out.
if (!_isUncon && {!isNil "ace_medical_feedback_fnc_playInjuredSound"}) then {
    [_patient, "hit"] call ace_medical_feedback_fnc_playInjuredSound;
};
