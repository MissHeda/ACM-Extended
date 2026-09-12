// ACM_breathing_fnc_checkBreathingLocal, overridden.
//
// two reasons this is a full override rather than a wrapper.
//
// 1. the Cheyne-Stokes special case. a patient with irregular respirations must not get the single-sample
//    normal, shallow or rapid line, because a one-shot read taken mid-pattern actively misleads. that used to
//    be a wrapper in fn_postInit that early-exited before calling through, and it is folded in below.
// 2. section 3.3 of the descriptor inventory. ACM emits the hint through
//        [QACEGVAR(common,displayTextStructured), [_hint, ...], _medic] call CBA_fnc_targetEvent
//    and ACE registers that event with LINKFUNC, which expands to plain FUNC(x) in a release build at
//    ace main/script_debug.hpp:12. the handler therefore captured the ORIGINAL function value when ACE's
//    XEH_postInit ran, so the displayTextStructured wrapper installed in our postInit never sees this call.
//    the keys have to be resolved to clinical text BEFORE the event is sent. the targetEvent itself is kept,
//    because checkBreathingLocal can run on a machine that is not the medic's and a direct call would drop the
//    hint in multiplayer.
//
// MACRO AUDIT. every macro in ACM's original was resolved against the ACM and ACE source before this file was
// written, because a macro expanded wrong returns a silent default rather than erroring. the two that are easy
// to get wrong:
//   GET_AIRWAYSTATE(unit) is NOT a variable read. main/script_macros.hpp:229 defines it as
//       ([unit] call EFUNC(airway,getAirwayState))
//   which resolves to ACM_airway_fnc_getAirwayState, a function this addon already overrides in
//   overrides/fn_getAirwayState.sqf. reading a variable instead would have bypassed our own airway model.
//   GET_AIRWAY_INFLAMMATION and GET_LUNG_TISSUEDAMAGE read out of the CBRN component, not airway:
//       main/script_macros.hpp:461  QEGVAR(CBRN,AirwayInflammation)
//       main/script_macros.hpp:467  QEGVAR(CBRN,LungTissueDamage)
//   ACM's own cbrn component writes these with QGVAR, which expands to the lowercase ACM_cbrn_ form, while the
//   macro reads the uppercase ACM_CBRN_ form. both work only because ArmA namespace variable names are
//   case-insensitive. the uppercase spelling is used here to match the macro definition, and
//   overrides/fn_getAirwayState.sqf:81 already uses the same spelling.
// the rest:
//   GET_RESPIRATION_RATE(unit)  ACM_breathing_RespirationRate, default 18   main/script_macros.hpp:248
//   GET_HEART_RATE(unit)        ace_medical_heartRate, default 80           ACE script_macros_medical.hpp:188
//   thresholds                  inflammation 15, lung tissue damage 20      main/script_macros.hpp:465, 469
params ["_medic", "_patient"];

// clinical wording resolver. returns the hardcore string when the descriptor setting is on and the ordinary
// localized string otherwise, so both registers flow through the same assignments.
private _lz = {
    params ["_k"];
    private _c = [_k] call ACME_fnc_clinTerm;
    if (_c isNotEqualTo "") exitWith { _c };
    localize _k
};

// A driving ventilator owns delivered breaths. Do not describe those mandatory breaths as the patient's
// spontaneous pattern or infer "low tidal volume" from pneumothorax/collapse flags alone. Report the actual
// delivered respiratory rate and exhaled tidal volume published by the ventilator model.
if ((missionNamespace getVariable ["ACME_sys_vent", true]) && {_patient getVariable ["ACME_vent_driving", false]} && {alive _patient}) exitWith {
    private _rr = (_patient getVariable ["ACME_vent_effectiveRR", 0]) max 0;
    private _vte = (_patient getVariable ["ACME_vent_vte", 0]) max 0;
    private _mv = (_patient getVariable ["ACME_vent_mvDelivered", 0]) max 0;
    private _hint = if (_vte < 50 || {_mv < 0.2}) then {
        format ["Patient is mechanically ventilated at %1 breaths/min; effective exhaled tidal volume is minimal.", round _rr]
    } else {
        format ["Patient is mechanically ventilated at %1 breaths/min with approximately %2 mL exhaled tidal volume.", round _rr, round _vte]
    };
    ["ace_common_displayTextStructured", [_hint, 2, _medic], _medic] call CBA_fnc_targetEvent;
    [_patient, "quick_view", "%1 checked breathing: mechanically ventilated, RR %2, VTe %3 mL",
        [[_medic, false, true] call ace_common_fnc_getName, round _rr, round _vte]] call ace_medical_treatment_fnc_addToLog;
};

// Cheyne-Stokes. reported as a pattern rather than as a sample.
if ((_patient getVariable ["ACME_cs_active", false]) && {alive _patient}) exitWith {
    ["ace_common_displayTextStructured", ["Breathing is irregular in rate and depth.", 2, _medic], _medic] call CBA_fnc_targetEvent;
    [_patient, "quick_view", "%1 checked breathing: irregular rate and depth", [[_medic, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
};

private _hintKey = "STR_ACM_Breathing_CheckBreathing_Normal";
private _hintLogKey = "STR_ACM_Breathing_CheckBreathing_Normal_Short";

private _respirationRate = _patient getVariable ["ACM_breathing_RespirationRate", 18];

private _pneumothorax = (_patient getVariable ["ACM_breathing_Pneumothorax_State", 0]) > 0;
private _tensionPneumothorax = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _tensionHemothorax = (_patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0]) > 1.4;

private _respiratoryArrest = (_respirationRate < 1
    || {(_patient getVariable ["ace_medical_heartRate", 80]) < 20}
    || {!(alive _patient)}
    || {_tensionPneumothorax}
    || {_tensionHemothorax});

// the function call, not a variable. see the macro audit above.
private _airwayBlocked = ([_patient] call ACM_airway_fnc_getAirwayState) == 0;
private _airwayCollapsed = (_patient getVariable ["ACM_airway_AirwayCollapse_State", 0]) > 0;
private _airwayReflexIntact = _patient getVariable ["ACM_airway_AirwayReflex_State", false];

private _airwayInflammation = (_patient getVariable ["ACM_CBRN_AirwayInflammation", 0]) > 15;
private _lungTissueDamaged = (_patient getVariable ["ACM_CBRN_LungTissueDamage", 0]) > 20;

private _airwayManeuver = (_patient getVariable ["ACM_airway_RecoveryPosition_State", false])
    || {_patient getVariable ["ACM_airway_HeadTilt_State", false]};
private _oral = _patient getVariable ["ACM_airway_AirwayItem_Oral", ""];
private _airwayAdjunct = (_oral == "OPA")
    || {(_patient getVariable ["ACM_airway_AirwayItem_Nasal", ""]) == "NPA"}
    || {_airwayManeuver};
private _airwaySecure = (_oral == "SGA") || {_airwayManeuver};

private _hintHeight = 1.5;

// the switch is ACM's, unchanged. only the strings it selects are resolved differently.
// note the precedence in ACM's second case is left as written: the || and && bind as ACM wrote them, and
// rewriting it "more clearly" would change which casualties read as shallow.
switch (true) do {
    case (_respiratoryArrest || _airwayBlocked): {
        _hintKey = "STR_ACM_Breathing_CheckBreathing_None";
        _hintLogKey = "STR_ACM_Breathing_CheckBreathing_None_Short";
    };
    case (_pneumothorax || _airwayCollapsed && !_airwaySecure || !_airwaySecure && !_airwayReflexIntact && !_airwayAdjunct || _airwayInflammation || _lungTissueDamaged): {
        _hintKey = "STR_ACM_Breathing_CheckBreathing_Shallow";
        _hintLogKey = "STR_ACM_Breathing_CheckBreathing_Shallow_Short";

        if (_respirationRate < 15.9) then {
            _hintKey = "STR_ACM_Breathing_CheckBreathing_ShallowSlow";
            _hintLogKey = "STR_ACM_Breathing_CheckBreathing_ShallowSlow_Short";
            _hintHeight = 2;
        } else {
            if (_respirationRate > 22) then {
                _hintKey = "STR_ACM_Breathing_CheckBreathing_ShallowRapid";
                _hintLogKey = "STR_ACM_Breathing_CheckBreathing_ShallowRapid_Short";
                _hintHeight = 2;
            };
        };
    };
    case (_respirationRate < 15.9): {
        _hintKey = "STR_ACM_Breathing_CheckBreathing_Slow";
        _hintLogKey = "STR_ACM_Breathing_CheckBreathing_Slow_Short";
    };
    case (_respirationRate > 22): {
        _hintKey = "STR_ACM_Breathing_CheckBreathing_Rapid";
        _hintLogKey = "STR_ACM_Breathing_CheckBreathing_Rapid_Short";
    };
    default {};
};

// resolved here, before the event is sent, for the LINKFUNC reason in the header.
private _hint = [_hintKey] call _lz;
private _hintLog = [_hintLogKey] call _lz;

["ace_common_displayTextStructured", [_hint, _hintHeight, _medic], _medic] call CBA_fnc_targetEvent;
[_patient, "quick_view", localize "STR_ACM_Breathing_CheckBreathing_ActionLog", [[_medic, false, true] call ace_common_fnc_getName, _hintLog]] call ace_medical_treatment_fnc_addToLog;
