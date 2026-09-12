// an ACME override of ace_medical_treatment_fnc_checkpulselocal, registered at compile time through CfgFunctions.
// this addon loads after ACM core, so it wins.
// it is a de-macroed copy of the override of ACM core plus one rule: torsades, ACME rhythm 102, is pulseless
// polymorphic vt. the electrical activity shows on the monitor and there is no mechanical pulse to palpate.
// we force the palpated rate to 0, so a pulse check reports no pulse while the monitor, driven by
// ace_medical_heartRate and the rhythm var, keeps showing torsades.
// _this is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];

private _heartRate = 0;

if !([_patient, _bodyPart] call ace_medical_treatment_fnc_hasTourniquetAppliedTo) then {
    _heartRate = switch (true) do {
        case (alive (_patient getVariable ["ace_medical_CPR_provider", objNull])): {
            random [100, 110, 120];  // fake rate. patient is dead and off the state machine, but CPR is running
        };
        case (alive _patient): {
            _patient getVariable ["ace_medical_heartRate", 80];
        };
        default { 0 };
    };
};

// pulseless torsades: there is no palpable pulse regardless of the displayed or monitor rate.
if (!([_patient] call ACM_circulation_fnc_hasPulse) && {!alive (_patient getVariable ["ace_medical_CPR_provider", objNull])}) then { _heartRate = 0; };
if ([_patient, _bodyPart] call ACME_fnc_aajtOccludes) then {_heartRate = 0;};

// hardcore clinical wording. these keys are localized HERE, before they are emitted, so the wrappers on
// displayTextStructured and addToLog never see the key and cannot map it. this file resolves them itself.
// _lz returns the clinical string when the descriptor setting is on and the ordinary localized string
// otherwise, so every assignment below reads the same in both registers.
private _lz = {
    params ["_k"];
    private _c = [_k] call ACME_fnc_clinTerm;
    if (_c isNotEqualTo "") exitWith { _c };
    localize _k
};

private _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_5"] call _lz;
private _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_None"] call _lz;

if (_heartRate > 1) then {
    if (_medic call ace_medical_treatment_fnc_isMedic) then {
        _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_1"] call _lz;
        _logOutput = str round _heartRate;
    } else {
        _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_2"] call _lz;
        _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Weak"] call _lz;

        if (_heartRate > 60) then {
            if (_heartRate > 100) then {
                _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_3"] call _lz;
                _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Strong"] call _lz;
            } else {
                _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_4"] call _lz;
                _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Normal"] call _lz;
            };
        };
    };
};

[_patient, "quick_view", localize "STR_ACE_medical_treatment_Check_Pulse_Log", [_medic call ace_common_fnc_getName, _logOutput]] call ace_medical_treatment_fnc_addToLog;

["ace_common_displayTextStructured", [[_heartRateOutput, _patient call ace_common_fnc_getName, round _heartRate], 1.5, _medic], _medic] call CBA_fnc_targetEvent;
