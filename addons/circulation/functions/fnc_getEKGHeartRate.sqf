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

// ACME monitor rate conditioner. The LifePak calls getEKGHeartRate from the audible beep, the large HR readout
// and the waveform generator. Conditioning the changing organized rate here gives all three consumers the exact
// same electrical clock instead of letting each redraw see a slightly different instantaneous value. Fixed arrest
// and custom-rhythm rates below remain exact and bypass this helper.
private _fnc_smoothTrackedRate = {
    params ["_raw"];
    if !(_raw isEqualType 0) exitWith {0};
    _raw = _raw max 0;

    private _now = CBA_missionTime;
    private _state = _patient getVariable ["ACME_AED_TrackedHRState", []];
    if !(_state isEqualType [] && {count _state >= 2}) exitWith {
        _patient setVariable ["ACME_AED_TrackedHRState", [_raw, _now], false];
        _raw
    };

    _state params ["_previous", "_lastTime"];
    if !(_previous isEqualType 0 && {_lastTime isEqualType 0}) exitWith {
        _patient setVariable ["ACME_AED_TrackedHRState", [_raw, _now], false];
        _raw
    };

    private _gap = _now - _lastTime;
    private _resetGap = missionNamespace getVariable ["ACME_monitorHRHardResetGap", 1.5];
    if (_gap < 0 || {_gap > _resetGap} || {_previous <= 0} || {_raw <= 0}) exitWith {
        _patient setVariable ["ACME_AED_TrackedHRState", [_raw, _now], false];
        _raw
    };

    // Cap how quickly the displayed/electrical rate can move from one frame to the next. This is not a delayed
    // average: it is a slew limiter, so a stable HR remains exact while a changing HR advances monotonically and
    // the R-R/T-wave timing does not jump by whole columns on every vitals poll.
    private _dt = (_gap max 0) min 0.25;
    private _delta = _raw - _previous;
    private _rise = missionNamespace getVariable ["ACME_monitorHRRiseBpmPerSec", 36];
    private _fall = missionNamespace getVariable ["ACME_monitorHRFallBpmPerSec", 48];
    private _limit = ((if (_delta >= 0) then {_rise} else {_fall}) max 1) * _dt;
    private _next = _previous + ((_delta max (-_limit)) min _limit);
    if (abs _delta < 0.20) then {_next = _raw;};

    _patient setVariable ["ACME_AED_TrackedHRState", [_next, _now], false];
    _next
};

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
        // The owner selects one rate for the PEA episode. Remote monitor clients only read it. 100 BPM is the safe
        // fallback for an old save/JIP frame that predates the seed; never reroll on every monitor/beep query.
        private _pea = _patient getVariable ["ACME_peaElectricalHR", 100];
        if (!(_pea isEqualType 0) || {_pea <= 0}) then {_pea = 100;};
        _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _pea];
        _pea
    };
    case ACM_Rhythm_VT;
    default { // Sinus / organized perfusing rhythm
        private _pr = GET_HEART_RATE(_patient);
        private _tracked = [_pr] call _fnc_smoothTrackedRate;
        _patient setVariable [QGVAR(CardiacArrest_EKG_HR), _tracked];
        _tracked;
    };
};