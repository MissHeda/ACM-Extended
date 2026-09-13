#include "..\script_component.hpp"
/*
 * Author: Blue
 * Get heart rate as generated from EKG
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * EKG Heart Rate <NUMBER>
 *
 * Example:
 * [player] call ACM_circulation_fnc_getEKGHeartRate;
 *
 * Public: No
 */

params ["_patient"];

// The monitor rate getter is deliberately side-effect free with respect to rate conditioning. The old slew limiter
// mutated its state every time this function was called; the beep loop, BPM display and waveform generator can all
// call it in the same frame, so each consumer received a slightly different rate and the trace visibly chased the
// sound. Native ACM physiology already owns the rate evolution. Every AED consumer now reads that same value.

private _fnc_generateHeartRate = { // ace_medical_vitals_fnc_updateHeartRate
    params ["_unit"];
    private _lastTimeUpdated = _unit getVariable [QACEGVAR(medical_vitals,lastTimeUpdated), 0];
    private _deltaT = (CBA_missionTime - _lastTimeUpdated) min 10;
    if (_deltaT < 1) exitWith {_unit getVariable [QGVAR(CardiacArrest_EKG_HR), (ACM_TARGETVITALS_HR(_unit))]};

    private _desiredHR = ACM_TARGETVITALS_HR(_unit);

    private _heartRate = _unit getVariable [QGVAR(CardiacArrest_EKG_HR), _desiredHR];

    private _hrChange = 0;
    private _bloodVolume = GET_BLOOD_VOLUME(_unit);
    private _targetHR = linearConversion [DEFAULT_BLOOD_VOLUME, BLOOD_VOLUME_CLASS_2_HEMORRHAGE, _bloodVolume, _desiredHR, (_desiredHR + 35)];
    
    private _oxygenSaturation = GET_OXYGEN(_unit);
    private _painLevel = GET_PAIN_PERCEIVED(_unit);

    if (_bloodVolume <= BLOOD_VOLUME_CLASS_2_HEMORRHAGE && _bloodVolume > BLOOD_VOLUME_CLASS_3_HEMORRHAGE) then {
        _targetHR = linearConversion [BLOOD_VOLUME_CLASS_2_HEMORRHAGE, BLOOD_VOLUME_CLASS_3_HEMORRHAGE, _bloodVolume, _desiredHR, (_desiredHR + 35)];
    };
    if (_bloodVolume <= BLOOD_VOLUME_CLASS_3_HEMORRHAGE) then {
        _targetHR = linearConversion [BLOOD_VOLUME_CLASS_3_HEMORRHAGE, BLOOD_VOLUME_CLASS_4_HEMORRHAGE, _bloodVolume, (_desiredHR + 35), (_desiredHR + 120)];
    };
    if (_painLevel > 0.2) then {
        _targetHR = _targetHR max (_desiredHR + 40 * _painLevel);
    };
    if (IS_BLEEDING(_unit)) then {
        _targetHR = _targetHR - ((10 * GET_WOUND_BLEEDING(_unit)) * (_painLevel + 0.1));
    };
    if (_bloodVolume > 3.9) then {
        _targetHR = _targetHR min ACM_TARGETVITALS_MAXHR(_unit);
    };
    
    // Increase HR to compensate for low blood oxygen/higher oxygen demand (e.g. running, recovering from sprint)
    private _oxygenDemand = _unit getVariable [VAR_OXYGEN_DEMAND, 0];
    private _targetOxygenHR = _targetHR + ((ACM_TARGETVITALS_OXYGEN(_unit) - _oxygenSaturation) * 2) + (_oxygenDemand * -1000);
    _targetOxygenHR = _targetOxygenHR min ACM_TARGETVITALS_MAXHR(_unit);

    _targetHR = _targetHR max _targetOxygenHR;

    if (_bloodVolume < (ACM_ASYSTOLE_BLOODVOLUME + 0.3)) then {
        _targetHR = _targetHR + 266 * (_bloodVolume - (ACM_ASYSTOLE_BLOODVOLUME + 0.3));
    };

    _hrChange = round(_targetHR - _heartRate) / 2;

    if (_hrChange < 0) then {
        _heartRate = (_heartRate + _deltaT * _hrChange) max _targetHR;
    } else {
        _heartRate = (_heartRate + _deltaT * _hrChange) min _targetHR;
    };

    _heartRate = _heartRate max 30;

    _unit setVariable [QGVAR(CardiacArrest_EKG_HR), _heartRate];

    _heartRate;
};

if (alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull])) exitWith {GET_HEART_RATE(_patient)};

private _rhythm = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];

if ([_patient] call FUNC(recentAEDShock) || !(alive _patient)) exitWith {0};

// ACME custom rhythms retain a native ACM proxy for treatment/arrest semantics, but their electrical rate is the
// explicit rhythm target. Returning it here makes the beep, BPM number, and EKG generator consume one source.
private _effective = [_patient] call ACME_fnc_rhythmGet;
if (_effective >= 100) exitWith {
    private _target = _patient getVariable ["ACME_rhythm_targetHR", 0];
    if (_target > 0) then {_target} else {GET_HEART_RATE(_patient)}
};

switch (_rhythm) do {
    case ACM_Rhythm_Asystole: { // Asystole
        _patient setVariable [QGVAR(CardiacArrest_EKG_HR), 0];
        0;
    };
    case ACM_Rhythm_VF: { // Ventricular Fibrillation
        missionNamespace getVariable ["ACME_rhythm_vfElectricalHR", 170]
    };
    case ACM_Rhythm_PVT: { // (Pulseless) Ventricular Tachycardia
        missionNamespace getVariable ["ACME_rhythm_pvtElectricalHR", 220]
    };
    case ACM_Rhythm_PEA: { // Pulseless Electrical Activity (Reversible)
        // PEA fluctuates deterministically from a single networked seed/start pair. Quantizing the time input to 4 Hz
        // gives the beep, numeric HR and waveform generator the same value when they query in the same frame, while
        // avoiding any recurring network HR updates.
        private _seed = _patient getVariable ["ACME_peaElectricalHR", 80];
        if (!(_seed isEqualType 0) || {!finite _seed}) then {_seed = 80;};
        _seed = (60 max _seed) min 100;
        private _start = _patient getVariable ["ACME_peaElectricalStart", _patient getVariable [QGVAR(ReversibleCardiacArrest_Time), CBA_missionTime]];
        if (!(_start isEqualType 0) || {!finite _start}) then {_start = CBA_missionTime;};
        private _hz = (missionNamespace getVariable ["ACME_peaVariationHz", 4]) max 1;
        private _t = floor (((CBA_missionTime - _start) max 0) * _hz) / _hz;
        private _phase = (_seed * 17.31) mod 360;
        private _pea = 80
            + (11 * sin ((_phase + (_t * 21)) mod 360))
            + (7 * sin (((_phase * 0.61) + 113 + (_t * 49)) mod 360))
            + (3.5 * sin (((_phase * 1.37) + 47 + (_t * 83)) mod 360));
        _pea = (60 max _pea) min 100;
        _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _pea];
        _pea
    };
    case ACM_Rhythm_VT;
    default { // Sinus / organized perfusing rhythm
        private _pr = GET_HEART_RATE(_patient);
        if (!(_pr isEqualType 0) || {!finite _pr}) then {_pr = 0;};
        _pr = _pr max 0;
        _patient setVariable ["ACME_AED_TrackedHRState", nil, false];
        _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _pr];
        _pr;
    };
};