// the rocuronium paralysis state machine, called per patient from the circulation tick. B17 applies the same
// pharmacologic block to AI and player casualties. rocuronium is a pure
// paralytic: it immobilizes skeletal muscle, the respiratory muscles included, which gives apnea, and it
// provides no sedation. the clinical model here has four parts.
// onset. paralysis is not instant. once a paralyzing dose is on board we timestamp it, and paralysis becomes
// fully established after the real onset, about 60 s. the apnea, the breathing effect, is carried by the
// medication config, and this function owns the movement lock and the awake-paralysis danger.
// paralyzed. the patient is locked incapacitated and cannot move or act. they also cannot breathe on their own,
// so they must be ventilated, by a BVM or a vent. it is tracked as ACME_roc_paralyzed for the debug and stage 3.
// awake paralysis. if they are paralyzed without adequate ketamine anesthesia on board, that is the cardinal RSI
// error: an aware, paralyzed patient. it is flagged as ACME_roc_awakeParalysis for the debug and given a
// physiologic distress response, a tachycardia and hypertension from the unblunted stress of awake paralysis.
// wearing off. when the dose decays below the block threshold, paralysis lifts and the lock is released, unless
// another reason keeps them down.
// call it as [_patient] call ACME_fnc_rocuroniumTick.
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
private _dt = [_patient, "rocuronium", 0.25, 5] call ACME_fnc_clinicalTickDelta;
// the system toggle, read live, so unticking paralytics in addon options stops this system immediately and
// completely with no mission restart.
if !(missionNamespace getVariable ["ACME_sys_paralytic", true]) exitWith {};
if (isNull _patient || {!alive _patient} || {!(_patient isKindOf "CAManBase")}) exitWith {};

private _dose = [_patient] call ACME_fnc_rocuroniumOnBoard;
// the paralyzing dose. this defaulted to 3, which was unreachable, because the recorded dose scale is the
// concentration times ml over 100, so a full 10 ml rocuronium vial, 100 mg, which is about a 1 mg/kg intubating
// dose, records only 1.0. a threshold of 3 needed thirty milliliters, so rocuronium almost certainly never
// paralyzed anyone.
// fn_debugmenu was already using 0.5 for this same variable, so the two disagreed. 0.5 is the correct one: 0.5 is
// 5 ml, which is 50 mg, so a genuine intubating dose crosses it comfortably and a token squirt does not.
private _blockThresh = missionNamespace getVariable ["ACME_roc_blockThreshold", 0.5];
private _onsetSec = missionNamespace getVariable ["ACME_roc_onsetSeconds", 60];  // about 60 s to a full block.
private _wasParalyzed = _patient getVariable ["ACME_roc_paralyzed", false];
private _now = CBA_missionTime;

if (_dose >= _blockThresh) then {
    // a paralyzing dose is on board. stamp the onset on the first tick we see it.
    private _onsetT0 = _patient getVariable ["ACME_roc_onsetT0", -1];
    if (_onsetT0 < 0) then {
        _onsetT0 = _now;
        [_patient, "ACME_roc_onsetT0", _onsetT0] call ACME_fnc_setVarNet;
    };
    // paralysis becomes fully established after the onset window.
    private _established = true; // B13: _dose already includes native onset; do not delay twice.
    if (_established && {!_wasParalyzed}) then {
        [_patient, true, true, true] call ACME_fnc_rocParalysisCommit;
        // lock the patient incapacitated, meaning immobile. this is the closest engine state to flaccid paralysis.
        if (!isNil "ace_medical_fnc_setUnconscious") then {
            [_patient, true] call ace_medical_fnc_setUnconscious;
        };
        [_patient, true, true, true, false] call ACME_fnc_rocApneaCommit;  // the respiratory muscles are out, so they must be ventilated.
    };
} else {
    // the dose decayed below the block, so paralysis wears off. clear the onset and the apnea, and release the lock
    // unless the patient is unconscious for another reason: sedation, a low GCS, arrest, a TBI or being
    // intubated.
    [_patient, "ACME_roc_onsetT0", -1] call ACME_fnc_setVarNet;
    if (_wasParalyzed) then {
        [_patient, false, true, true] call ACME_fnc_rocParalysisCommit;
        [_patient, false, true, true, false] call ACME_fnc_rocApneaCommit;
        [_patient, false, true, true, false] call ACME_fnc_rocAwakeParalysisCommit;
        private _sedLoad = [_patient] call ACME_fnc_sedationOnBoard;
        private _sedThresh = (call ACME_fnc_sedationThreshold);
        private _otherReason = (_sedLoad >= _sedThresh)
            || {(_patient getVariable ["ACM_core_TargetVitals_GCS", 15]) < 8}
            || {_patient getVariable ["ace_medical_inCardiacArrest", false]}
            || {_patient getVariable ["ACME_tbi_HasTBI", false]};
        if (!_otherReason) then {
            if (!isNil "ace_medical_fnc_setUnconscious") then {
                [_patient, false] call ace_medical_fnc_setUnconscious;
            };
        };
    };
};

// the awake-paralysis danger: paralyzed, perfusing, and not adequately sedated, which is the cardinal RSI error.
// Arrest cannot accumulate this stress, and ROSC has a short grace before the acute response can resume.
// it is deliberately silent. there is no popup and no hint, because the patient is conscious, in extremis, and
// physically unable to signal it, and that is the entire point of the error. the only evidence is on the
// monitor, a climbing heart rate and a rising blood pressure in a patient who should be flat, and it is the job
// of the provider to read that and understand what they did.
if (_patient getVariable ["ACME_roc_paralyzed", false]) then {
    // sedation means any adequate anesthetic on board, ketamine or midazolam, rather than ketamine alone.
    private _sedLoad = [_patient] call ACME_fnc_sedationOnBoard;
    private _sedThresh = (call ACME_fnc_sedationThreshold);
    private _inArrest = _patient getVariable ["ace_medical_inCardiacArrest", false];
    private _postROSCGrace = CBA_missionTime < (_patient getVariable ["ACME_roc_postROSCGraceUntil", 0]);
    private _awake = (!_inArrest) && {!_postROSCGrace} && {_sedLoad < _sedThresh};
    [_patient, _awake, true, true, false] call ACME_fnc_rocAwakeParalysisCommit;
    if (_awake) then {
        // the unblunted catecholamine surge of an aware, paralyzed patient: tachycardia and hypertension.
        private _dwell = (_patient getVariable ["ACME_roc_awakeDwell", 0]) + _dt;  // the circ tick period.

        // tachycardia. it publishes a target hr drive instead of writing the hr target here. circhandle folds
        // ACME_hrDrive_roc into its combined _hrDrive, through max, because a stress response raises the hr floor, and
        // does the one final write. this removes the double-write that had rocuronium set hr and then had circhandle's
        // own final write clobber it a few lines later in the same tick. that is an order-dependent contention, and
        // exactly the two-writers-on-one-vital class we are eliminating for 1.0. the drive is an absolute target that
        // ramps up over time, and -1 means no drive, cleared below when they are not awake-paralyzed.
        private _hrRate = missionNamespace getVariable ["ACME_roc_awakeHRRate", 0.35];  // bpm per second.
        private _rocPrev = _patient getVariable ["ACME_hrDrive_roc", -1];
        private _rocBase = if (_rocPrev >= 0) then { _rocPrev } else { _patient getVariable ["ACM_core_TargetVitals_HeartRate", 80] };
        private _hrMax = missionNamespace getVariable ["ACME_roc_awakeHRMax", 138];
        private _hrDriveNext = ((_rocBase + (_hrRate * _dt)) min _hrMax);

        // hypertension. it is routed through real peripheral resistance, where bp is co times r, the same working channel
        // the pressors use. the old ACME_roc_awakeBPbump was written and never read by anything, so the hypertension
        // half of the stress response never actually reached the patient. this one does.
        private _resistMax = missionNamespace getVariable ["ACME_roc_awakeResistMax", 20];
        private _resistRate = missionNamespace getVariable ["ACME_roc_awakeResistRate", 0.30];  // per second.
        private _r = (_patient getVariable ["ACME_roc_awakeResistAdd", 0]) + (_resistRate * _dt);
        private _resistNext = (_r min _resistMax);
        [_patient, "KEEP", _dwell, _resistNext, _hrDriveNext, true, true] call ACME_fnc_rocStressStateCommit;

        // a latching awareness event. once they have been aware and paralyzed for more than a moment, that happened, and
        // sedating them afterwards does not un-happen it. the flag persists, through later sedation and through the
        // paralysis wearing off, until a full heal, so the aar can score it. without this the single worst RSI error in
        // the mod evaporated the moment you belatedly pushed the ketamine.
        private _latchSecs = missionNamespace getVariable ["ACME_roc_awarenessLatchSeconds", 5];
        private _awarenessSeconds = (_patient getVariable ["ACME_roc_awarenessSeconds", 0]) + _dt;
        if (_dwell >= _latchSecs && {!(_patient getVariable ["ACME_roc_awarenessEvent", false])}) then {
            [_patient, true, CBA_missionTime, _awarenessSeconds, true, true] call ACME_fnc_rocAwarenessStateCommit;
        } else {
            [_patient, "KEEP", "KEEP", _awarenessSeconds, true, true] call ACME_fnc_rocAwarenessStateCommit;
        };
    } else {
        // sedation caught up, so the acute stress response settles. the awareness event does not clear.
        private _r = (_patient getVariable ["ACME_roc_awakeResistAdd", 0]) - ((missionNamespace getVariable ["ACME_roc_awakeResistClearRate", 1.2]) * _dt);
        [_patient, "KEEP", 0, (_r max 0), -1, true, true] call ACME_fnc_rocStressStateCommit;  // release the tachycardia HR drive back to circHandle.
    };
} else {
    [_patient, false, true, true, false] call ACME_fnc_rocAwakeParalysisCommit;
    private _r = (_patient getVariable ["ACME_roc_awakeResistAdd", 0]) - ((missionNamespace getVariable ["ACME_roc_awakeResistClearRate", 1.2]) * _dt);
    [_patient, "KEEP", 0, (_r max 0), -1, true, true] call ACME_fnc_rocStressStateCommit;  // release the tachycardia HR drive back to circHandle.
};
