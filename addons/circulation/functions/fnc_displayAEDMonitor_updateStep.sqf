#include "..\script_component.hpp"
#include "..\Defibrillator_defines.hpp"
/*
 * Author: Blue
 * Handle vitals graphs during step update
 *
 * Arguments:
 * 0: Dialog Control <DISPLAY>
 * 1: Patient <OBJECT>
 * 2: Step in array <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), player, 0] call ACM_circulation_fnc_displayAEDMonitor_updateStep;
 *
 * Public: No
 */

params ["_dlg", "_patient", "_updateStep"];

// The display loop historically advances 175 -> 176 for one frame even though the valid waveform indices are
// 0..175. Selecting index 176 leaves a missing segment at every sweep wrap and can throw the rest of the update
// for that frame. Fold any invalid step back to the first drawable segment and publish the corrected index so the
// next PFH frame continues at 2 rather than repeating the bad value.
if !(_updateStep isEqualType 0) then {_updateStep = 1;};
_updateStep = floor _updateStep;
if (_updateStep < 1 || {_updateStep >= AED_MONITOR_WIDTH}) then {
    _updateStep = 1;
    _patient setVariable [QGVAR(AED_UpdateStep), _updateStep];
};
private _previousIndex = _updateStep - 1;

private _monitorArray_EKGRefresh = _patient getVariable [QGVAR(AED_EKGRefreshDisplay), []];
private _monitorArray_PORefresh = _patient getVariable [QGVAR(AED_PORefreshDisplay), []];
private _monitorArray_CORefresh = _patient getVariable [QGVAR(AED_CORefreshDisplay), []];

private _monitorArray_EKG = _patient getVariable [QGVAR(AED_EKGDisplay), []];
private _monitorArray_PO = _patient getVariable [QGVAR(AED_PODisplay), []];
private _monitorArray_CO = _patient getVariable [QGVAR(AED_CODisplay), []];

// At sweep wrap, sample 0 is the new left-edge time anchor. Refresh it before drawing segment 0 -> 1; leaving
// sample 0 from the previous sweep is what created the recurring disconnected line at the left edge.
if (_updateStep == 1) then {
    if (count _monitorArray_EKGRefresh > 0) then {
        if (count _monitorArray_EKG < 1) then {_monitorArray_EKG resize [1, 0];};
        _monitorArray_EKG set [0, _monitorArray_EKGRefresh select 0];
    };
    if (count _monitorArray_PORefresh > 0) then {
        if (count _monitorArray_PO < 1) then {_monitorArray_PO resize [1, 0];};
        _monitorArray_PO set [0, _monitorArray_PORefresh select 0];
    };
    if (count _monitorArray_CORefresh > 0) then {
        if (count _monitorArray_CO < 1) then {_monitorArray_CO resize [1, 0];};
        _monitorArray_CO set [0, _monitorArray_CORefresh select 0];
    };
};

// The left endpoint must always come from what is ACTUALLY on screen. During a mid-sweep HR/rhythm refresh the
// refresh buffer can be regenerated underneath the already-drawn columns. Using refresh[previous] as the old
// endpoint makes the new line begin at a value that was never drawn, which is the visible disconnected/gapped
// segment. The committed display arrays are the continuity authority; only the right endpoint comes from refresh.
private _ekgPrevious = if (_previousIndex < count _monitorArray_EKG) then {_monitorArray_EKG select _previousIndex} else {0};
private _poPrevious = if (_previousIndex < count _monitorArray_PO) then {_monitorArray_PO select _previousIndex} else {0};
private _coPrevious = if (_previousIndex < count _monitorArray_CO) then {_monitorArray_CO select _previousIndex} else {0};

private _ekgTarget = if (_updateStep < count _monitorArray_EKGRefresh) then {_monitorArray_EKGRefresh select _updateStep} else {_ekgPrevious};
private _poTarget = if (_updateStep < count _monitorArray_PORefresh) then {_monitorArray_PORefresh select _updateStep} else {_poPrevious};
private _coTarget = if (_updateStep < count _monitorArray_CORefresh) then {_monitorArray_CORefresh select _updateStep} else {_coPrevious};

if (_updateStep >= count _monitorArray_EKG) then {_monitorArray_EKG resize (_updateStep + 1);};
if (_updateStep >= count _monitorArray_PO) then {_monitorArray_PO resize (_updateStep + 1);};
if (_updateStep >= count _monitorArray_CO) then {_monitorArray_CO resize (_updateStep + 1);};

_monitorArray_EKG set [_updateStep, _ekgTarget];
_monitorArray_PO set [_updateStep, _poTarget];
_monitorArray_CO set [_updateStep, _coTarget];
_patient setVariable [QGVAR(AED_EKGDisplay), _monitorArray_EKG];
_patient setVariable [QGVAR(AED_PODisplay), _monitorArray_PO];
_patient setVariable [QGVAR(AED_CODisplay), _monitorArray_CO];

private _padsState = [_patient, "", 1] call FUNC(hasAED);
private _pulseOximeterState = [_patient, "", 2] call FUNC(hasAED);
private _capnographState = [_patient, "", 4] call FUNC(hasAED);

// Control N renders the line from sample N to N+1. The target sample is _updateStep, therefore the line control
// is _previousIndex. Using _updateStep rendered every ECG segment one column late relative to the beat clock.
[_dlg, 0, _previousIndex, _ekgPrevious, _ekgTarget, _padsState] call FUNC(displayAEDMonitor_adjustWaveform);
[_dlg, 1, _previousIndex, _poPrevious, _poTarget, _pulseOximeterState] call FUNC(displayAEDMonitor_adjustWaveform);
[_dlg, 2, _previousIndex, _coPrevious, _coTarget, _capnographState] call FUNC(displayAEDMonitor_adjustWaveform);
