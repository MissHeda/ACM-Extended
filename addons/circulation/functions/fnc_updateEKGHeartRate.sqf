#include "..\script_component.hpp"
/*
 * Update the AED electrical-rate cache at a controlled cadence.
 *
 * ACM/ACE own the physiologic vital-sign update cadence.  This function does not
 * advance the mechanical heart rate or any arrest state; it only samples the
 * electrical rate used by the AED for rhythms whose monitor rate is not the
 * mechanical pulse rate (PEA/VF/PVT).  Keeping the write here, once per second,
 * makes getEKGHeartRate a true read-only accessor so multiple monitor consumers
 * in one frame cannot advance the same vital twice.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * Electrical HR <NUMBER>
 */
params ["_patient"];

if (isNull _patient) exitWith {0};

private _now = CBA_missionTime;
private _rhythm = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];
private _effective = [_patient] call ACME_fnc_rhythmGet;
private _rateRhythm = if (_effective >= 100) then {_effective} else {_rhythm};
private _previousRateRhythm = _patient getVariable ["ACME_AED_ElectricalRateRhythm", -999];
private _rateRhythmChanged = _previousRateRhythm != _rateRhythm;
if (_rateRhythmChanged) then {
    _patient setVariable ["ACME_AED_ElectricalRateRhythm", _rateRhythm, false];
    _patient setVariable ["ACME_AED_ElectricalRateLastUpdate", -1, false];
    if (_rhythm == ACM_Rhythm_PEA) then {
        _patient setVariable ["ACME_PEA_ElectricalGoalUntil", -1, false];
    };
};

if (alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull])) exitWith {
    private _hr = GET_HEART_RATE(_patient) max 0;
    _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _hr, false];
    _hr
};

if ([_patient] call FUNC(recentAEDShock) || {!(alive _patient)}) exitWith {
    _patient setVariable [QGVAR(CardiacArrest_EKG_HR), 0, false];
    0
};

// Custom perfusing rhythms already have one explicit target rate.  Do not add a
// second slew controller on top of it.
if (_effective >= 100) exitWith {
    private _target = _patient getVariable ["ACME_rhythm_targetHR", GET_HEART_RATE(_patient)];
    if (!(_target isEqualType 0) || {!finite _target}) then {_target = GET_HEART_RATE(_patient);};
    _target = _target max 0;
    _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _target, false];
    _target
};

if (_rhythm == ACM_Rhythm_Asystole) exitWith {
    _patient setVariable [QGVAR(CardiacArrest_EKG_HR), 0, false];
    0
};

// Sinus and VT-with-pulse use ACM/ACE's mechanical HR directly.  That rate is
// already integrated exactly once by handleUnitVitals/updateHeartRate.
if (_rhythm in [ACM_Rhythm_Sinus, ACM_Rhythm_VT]) exitWith {
    private _hr = GET_HEART_RATE(_patient);
    if (!(_hr isEqualType 0) || {!finite _hr}) then {_hr = 0;};
    _hr = _hr max 0;
    _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _hr, false];
    _hr
};

private _last = _patient getVariable ["ACME_AED_ElectricalRateLastUpdate", -1];
private _cached = _patient getVariable [QGVAR(CardiacArrest_EKG_HR), 0];
if (!(_cached isEqualType 0) || {!finite _cached}) then {_cached = 0;};

// Match ACE/ACM's one-second vital update cadence.  The AED PFH may execute every
// frame, but it must not mutate a vital every frame.
if (_last >= 0 && {(_now - _last) < 1}) exitWith {_cached max 0};
private _dt = if (_last < 0) then {1} else {((_now - _last) max 1) min 5};
_patient setVariable ["ACME_AED_ElectricalRateLastUpdate", _now, false];

switch (_rhythm) do {
    case ACM_Rhythm_VF: {
        // VF has no meaningful organized ventricular rate, but ACM presents an
        // electrical-rate number.  Resample once per monitor-rate tick source,
        // not on every getter call, so every consumer sees the same number.
        _cached = round (100 + random 120);
    };
    case ACM_Rhythm_PVT: {
        // Preserve ACM's original polymorphic/pulseless VT electrical-rate band.
        _cached = round (random [200, 220, 240]);
    };
    case ACM_Rhythm_PEA: {
        // Start from ACM's original physiologic PEA driver: hemorrhage, oxygen,
        // pain and active bleeding shape the electrical target.  Then constrain
        // PEA to the requested organized 60-100 range and give it a slow,
        // unstable wandering set-point rather than a fixed 100/101 BPM.
        private _desiredHR = ACM_TARGETVITALS_HR(_patient);
        private _bloodVolume = GET_BLOOD_VOLUME(_patient);
        private _targetHR = linearConversion [DEFAULT_BLOOD_VOLUME, BLOOD_VOLUME_CLASS_2_HEMORRHAGE, _bloodVolume, _desiredHR, (_desiredHR + 35)];
        private _oxygenSaturation = GET_OXYGEN(_patient);
        private _painLevel = GET_PAIN_PERCEIVED(_patient);

        if (_bloodVolume <= BLOOD_VOLUME_CLASS_2_HEMORRHAGE && {_bloodVolume > BLOOD_VOLUME_CLASS_3_HEMORRHAGE}) then {
            _targetHR = linearConversion [BLOOD_VOLUME_CLASS_2_HEMORRHAGE, BLOOD_VOLUME_CLASS_3_HEMORRHAGE, _bloodVolume, _desiredHR, (_desiredHR + 35)];
        };
        if (_bloodVolume <= BLOOD_VOLUME_CLASS_3_HEMORRHAGE) then {
            _targetHR = linearConversion [BLOOD_VOLUME_CLASS_3_HEMORRHAGE, BLOOD_VOLUME_CLASS_4_HEMORRHAGE, _bloodVolume, (_desiredHR + 35), (_desiredHR + 120)];
        };
        if (_painLevel > 0.2) then {
            _targetHR = _targetHR max (_desiredHR + 40 * _painLevel);
        };
        if (IS_BLEEDING(_patient)) then {
            _targetHR = _targetHR - ((10 * GET_WOUND_BLEEDING(_patient)) * (_painLevel + 0.1));
        };
        if (_bloodVolume > 3.9) then {
            _targetHR = _targetHR min ACM_TARGETVITALS_MAXHR(_patient);
        };

        private _oxygenDemand = _patient getVariable [VAR_OXYGEN_DEMAND, 0];
        private _targetOxygenHR = _targetHR + ((ACM_TARGETVITALS_OXYGEN(_patient) - _oxygenSaturation) * 2) + (_oxygenDemand * -1000);
        _targetOxygenHR = _targetOxygenHR min ACM_TARGETVITALS_MAXHR(_patient);
        _targetHR = _targetHR max _targetOxygenHR;

        if (_bloodVolume < (ACM_ASYSTOLE_BLOODVOLUME + 0.3)) then {
            _targetHR = _targetHR + 266 * (_bloodVolume - (ACM_ASYSTOLE_BLOODVOLUME + 0.3));
        };

        // Map the broad ACM physiologic target into the organized PEA display
        // band while retaining directionality of deterioration/recovery.
        private _physGoal = linearConversion [35, 180, _targetHR, 62, 96, true];
        private _goalUntil = _patient getVariable ["ACME_PEA_ElectricalGoalUntil", -1];
        private _goal = _patient getVariable ["ACME_PEA_ElectricalGoal", -1];
        if (!(_goal isEqualType 0) || {!finite _goal}) then {_goal = -1;};

        if (_goal < 60 || {_now >= _goalUntil}) then {
            private _wander = random [-10, 0, 10];
            private _bias = if (_cached >= 94) then {-abs _wander} else {if (_cached <= 66) then {abs _wander} else {_wander}};
            _goal = ((_physGoal + _bias) max 60) min 100;
            _patient setVariable ["ACME_PEA_ElectricalGoal", _goal, false];
            _patient setVariable ["ACME_PEA_ElectricalGoalUntil", _now + random [1.8, 2.8, 4.2], false];
        };

        if (_cached < 60 || {_cached > 100}) then {
            private _seed = _patient getVariable ["ACME_peaElectricalHR", 80];
            if (!(_seed isEqualType 0) || {!finite _seed}) then {_seed = 80;};
            _cached = (_seed max 60) min 100;
        };

        private _maxStep = (missionNamespace getVariable ["ACME_peaElectricalMaxBpmPerSec", 6]) * _dt;
        private _delta = (_goal - _cached) max (-_maxStep) min _maxStep;
        // Small stochastic motion prevents long plateaus while the slower goal
        // provides coherent fluctuation rather than frame-to-frame noise.
        private _micro = random [-1.6, 0, 1.6];
        _cached = ((_cached + _delta + _micro) max 60) min 100;
    };
    default {
        _cached = GET_HEART_RATE(_patient) max 0;
    };
};

_patient setVariable [QGVAR(CardiacArrest_EKG_HR), _cached, false];
_cached
