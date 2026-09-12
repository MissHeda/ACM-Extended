/*
 * Author: Blue
 * Update lung state of patient
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Was Healed <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, false] call ACM_breathing_fnc_updateLungState;
 *
 * Public: No
 */

params ["_patient", ["_healed", false]];

if (_healed) exitWith {
    _patient setVariable ["ACM_breathing_Stethoscope_LungState", [0,0], true];
};

private _lungState = _patient getVariable ["ACM_breathing_Stethoscope_LungState", [0,0]];

private _affectedIndex = _lungState findIf {_x > 0};

if (_affectedIndex == -1) then {
    _affectedIndex = round (random 1);
};

private _state = 0;

private _PTXState = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _TPTXState = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _HTXFluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];

switch (true) do {
    case (_TPTXState || _HTXFluid > 1.1): {
        _state = 2;
    };
    case (_PTXState > 0 || _HTXFluid > 0.3): {
        _state = 1;
    };
    default {};
};

if (_state == 0) exitWith {
    // ACME: there is no pneumo or hemothorax on this patient, so check for over-resuscitation pulmonary edema.
    // the lung state of ACM is [left, right], so edema is modeled as diffuse crackles on both fields, where state 3
    // gives Crackles in usestethoscope.
    private _overload = _patient getVariable ["ACM_circulation_Overload_Volume", 0];
    if (_overload > (missionNamespace getVariable ["ACME_edema_threshold", 0.5])) then {
        _patient setVariable ["ACM_breathing_Stethoscope_LungState", [3,3], true];
    } else {
        _patient setVariable ["ACM_breathing_Stethoscope_LungState", [0,0], true];
    };
};

_lungState set [_affectedIndex, _state];

_patient setVariable ["ACM_breathing_Stethoscope_LungState", _lungState, true];