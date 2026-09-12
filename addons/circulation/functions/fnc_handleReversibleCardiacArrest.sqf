#include "..\script_component.hpp"
/* NA4: owner-local PEA lifecycle. Extended and native ROSC vetoes share one
   eligibility gate. Release the old worker BEFORE synchronous native callbacks:
   a rejected ROSC attempt must be able to install its replacement immediately. */
params ["_patient", ["_resume", false]];
private _acmeBinding = "NA4:handleReversibleCardiacArrest";
if (isNull _patient || {!local _patient} || {!alive _patient} || {!(IN_CRDC_ARRST(_patient))}) exitWith {};
if (_patient getVariable ["ACME_clinicalRestoring", false]) exitWith {};
if (_patient getVariable [QGVAR(ReversibleCardiacArrest_PFH), -1] >= 0) exitWith {};
// A PEA rhythm without a local handler is a recovery case, not a reason to exit.
private _old = _patient getVariable [QGVAR(CardiacArrest_PFH), -1];
if (_old >= 0) then {[_old] call CBA_fnc_removePerFrameHandler;};
_patient setVariable [QGVAR(CardiacArrest_PFH), -1, false];
_patient setVariable [QGVAR(ReversibleCardiacArrest_State), true, true];
if (isNil {_patient getVariable QGVAR(ReversibleCardiacArrest_Time)}) then {
    _patient setVariable [QGVAR(ReversibleCardiacArrest_Time), CBA_missionTime, true];
};
_patient setVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_PEA, true];
if (!_resume || {isNil {_patient getVariable "ACME_peaElectricalHR"}}) then {
    private _brady = (random 1) < (missionNamespace getVariable ["ACME_peaBradyChance", 0.25]);
    private _peaHR = if (_brady) then {
        round (random [
            missionNamespace getVariable ["ACME_peaBradyMinHR", 35],
            missionNamespace getVariable ["ACME_peaBradyModeHR", 45],
            missionNamespace getVariable ["ACME_peaBradyMaxHR", 58]
        ])
    } else {
        round (random [
            missionNamespace getVariable ["ACME_peaNormalMinHR", 90],
            missionNamespace getVariable ["ACME_peaNormalModeHR", 100],
            missionNamespace getVariable ["ACME_peaNormalMaxHR", 110]
        ])
    };
    _patient setVariable ["ACME_peaElectricalHR", _peaHR, true];
};
[_patient] call FUNC(updateCirculationState);
private _PFH = [{
    params ["_args", "_idPFH"];
    _args params ["_patient", "_owner", "_epoch"];
    private _ownsHandle = (_patient getVariable [QGVAR(ReversibleCardiacArrest_PFH), -1]) == _idPFH;
    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_ownsHandle}) exitWith {
        if (_ownsHandle) then {_patient setVariable [QGVAR(ReversibleCardiacArrest_PFH), -1, false];};
        [_idPFH] call CBA_fnc_removePerFrameHandler;
    };
    private _rhythm = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];
    private _stillArrested = alive _patient && {IN_CRDC_ARRST(_patient)};
    private _time = _patient getVariable [QGVAR(ReversibleCardiacArrest_Time), CBA_missionTime];
    private _timedOut = CBA_missionTime >= (_time + 360);
    // B67: the PEA worker consumes the exact same composed gate as ACM's attemptROSC override.
    // There is no second volume/oxygen/ACME-veto implementation here to drift out of sync.
    private _eligible = (([_patient, true] call FUNC(roscEligibility)) select 0);
    if (_stillArrested && {_rhythm == ACM_Rhythm_PEA} && {!_timedOut} && {!_eligible}) exitWith {};

    // All cleanup precedes callbacks; nothing below may erase a new PFH.
    _patient setVariable [QGVAR(ReversibleCardiacArrest_PFH), -1, false];
    _patient setVariable [QGVAR(ReversibleCardiacArrest_State), false, true];
    [_idPFH] call CBA_fnc_removePerFrameHandler;
    if (!_stillArrested || {_rhythm != ACM_Rhythm_PEA}) exitWith {
        _patient setVariable [QGVAR(ReversibleCardiacArrest_Time), nil, true];
        if (_stillArrested && {!(_rhythm in [ACM_Rhythm_Asystole, ACM_Rhythm_Sinus])}) then {
            [_patient, true] call FUNC(handleCardiacArrest);
        };
    };
    if (_timedOut) exitWith {
        _patient setVariable [QGVAR(ReversibleCardiacArrest_Time), nil, true];
        [QGVAR(handleCardiacArrest), _patient] call CBA_fnc_localEvent;
    };
    // Preserve the original deadline during a refused attempt. The synchronous
    // fallback may create another reversible worker. Never reset its fields here.
    [QGVAR(attemptROSC), _patient] call CBA_fnc_localEvent;
    if (!(IN_CRDC_ARRST(_patient)) && {_patient getVariable [QGVAR(ReversibleCardiacArrest_PFH), -1] < 0}) then {
        _patient setVariable [QGVAR(ReversibleCardiacArrest_Time), nil, true];
    };
}, 5, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;
_patient setVariable [QGVAR(ReversibleCardiacArrest_PFH), _PFH, false];
