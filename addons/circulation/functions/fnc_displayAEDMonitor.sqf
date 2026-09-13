#include "..\script_component.hpp"
#include "..\Defibrillator_defines.hpp"
/*
 * Author: Blue
 * Display AED Monitor visuals
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget] call ACM_circulation_fnc_displayAEDMonitor;
 *
 * Public: No
 */

params ["_medic", "_patient"];

GVAR(AED_ReOpenMenu) = ACEGVAR(medical_gui,pendingReopen);

ACEGVAR(medical_gui,pendingReopen) = false; // Prevent medical menu from reopening

if (dialog) then { // If another dialog is open (medical menu) close it
    closeDialog 0;
};

createDialog QGVAR(Lifepak_Monitor_Dialog);

GVAR(EKG_Tick) = CBA_missionTime;

GVAR(AED_Monitor_Target) = _patient;

uiNamespace setVariable [QGVAR(AEDMonitor_DLG),(findDisplay IDC_LIFEPAK_MONITOR)];

private _padsState = [_patient, "", 1] call FUNC(hasAED);
private _pulseOximeterState = [_patient, "", 2] call FUNC(hasAED);
private _capnographState = [_patient, "", 4] call FUNC(hasAED);
_patient setVariable [QGVAR(AED_Monitor_HR), [_patient] call FUNC(getEKGHeartRate)];

private _saturation = _patient getVariable [QGVAR(AED_PulseOximeter_Display), -1];
_patient setVariable [QGVAR(AED_Monitor_OxygenSaturation), _saturation];

private _etco2 = _patient getVariable [QGVAR(AED_CO2_Display), 0];
private _rr = GET_RESPIRATION_RATE(_patient);
_patient setVariable [QGVAR(AED_Monitor_EtCO2), _etco2];

private _rhythm = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];

if !(alive _patient) then {
    _rhythm = ACM_Rhythm_Asystole;
};

_patient setVariable [QGVAR(AED_EKGRhythm), _rhythm];

private _recentShock = [_patient, true] call FUNC(recentAEDShock);

private _HRSpacing = 0;

if (_rhythm in [ACM_Rhythm_CPR,ACM_Rhythm_Sinus,ACM_Rhythm_PEA]) then {
    private _initialEKGHR = [_patient] call FUNC(getEKGHeartRate);
    if (_initialEKGHR > 0) then {
        _HRSpacing = (60 / _initialEKGHR) * AED_SPACING_MULTIPLIER;
    } else {
        _HRSpacing = 0;
    };
};

if (count (_patient getVariable [QGVAR(AED_EKGDisplay), []]) < AED_MONITOR_WIDTH || !(_patient getVariable [QGVAR(AED_Monitor_Pads_State), false])) then { // Initial
    //_ekgDisplay resize [AED_MONITOR_WIDTH, 0];
    if (_padsState) then {
        _patient setVariable [QGVAR(AED_Monitor_Pads_State), true, true];
        if (_rhythm in [ACM_Rhythm_CPR,ACM_Rhythm_Sinus,ACM_Rhythm_PEA,ACM_Rhythm_VT]) then {
            _patient setVariable [QGVAR(AED_EKGDisplay), (([_rhythm, _HRSpacing, 0] call FUNC(displayAEDMonitor_generateEKG)) select 0)];
        } else {
            if (_recentShock) then {
                _patient setVariable [QGVAR(AED_EKGDisplay), (([1, -1, 0] call FUNC(displayAEDMonitor_generateEKG)) select 0)];
            } else {
                _patient setVariable [QGVAR(AED_EKGDisplay), (([_rhythm, -1, 0] call FUNC(displayAEDMonitor_generateEKG)) select 0)];
            };
        };
    };
}; 

if (count (_patient getVariable [QGVAR(AED_PODisplay), []]) < AED_MONITOR_WIDTH || !(_patient getVariable [QGVAR(AED_Monitor_PulseOximeter_State), false])) then { // Initial
    if (_pulseOximeterState) then {
        _patient setVariable [QGVAR(AED_Monitor_PulseOximeter_State), true, true];
        if (_rhythm in [ACM_Rhythm_CPR,ACM_Rhythm_Sinus,ACM_Rhythm_PEA,ACM_Rhythm_VT]) then {
            _patient setVariable [QGVAR(AED_PODisplay), (([_rhythm, _HRSpacing, 0, _saturation] call FUNC(displayAEDMonitor_generatePO)) select 0)];
        } else {
            if (_recentShock) then {
                _patient setVariable [QGVAR(AED_PODisplay), (([1, -1, 0, _saturation] call FUNC(displayAEDMonitor_generatePO)) select 0)];
            } else {
                _patient setVariable [QGVAR(AED_PODisplay), (([_rhythm, -1, 0, _saturation] call FUNC(displayAEDMonitor_generatePO)) select 0)];
            };
        };
    };
};

if (count (_patient getVariable [QGVAR(AED_CODisplay), []]) < AED_MONITOR_WIDTH || !(_patient getVariable [QGVAR(AED_Monitor_Capnograph_State), false])) then { // Initial
    if (_capnographState) then {
        _patient setVariable [QGVAR(AED_Monitor_Capnograph_State), true, true];
        if (_rhythm in [ACM_Rhythm_CPR,ACM_Rhythm_Sinus,ACM_Rhythm_PEA,ACM_Rhythm_VT]) then {
            _patient setVariable [QGVAR(AED_CODisplay), (([_rhythm, _HRSpacing, 0, _etco2, _rr] call FUNC(displayAEDMonitor_generateCO)) select 0)];
        } else {
            if (_recentShock) then {
                _patient setVariable [QGVAR(AED_CODisplay), (([1, -1, 0, 0, 0] call FUNC(displayAEDMonitor_generateCO)) select 0)];
            } else {
                _patient setVariable [QGVAR(AED_CODisplay), (([_rhythm, -1, 0, _etco2, _rr] call FUNC(displayAEDMonitor_generateCO)) select 0)];
            };
        };
    };
};

// Sync up waveforms
private _monitorArray_EKG = _patient getVariable [QGVAR(AED_EKGDisplay), []];
private _monitorArray_PO = _patient getVariable [QGVAR(AED_PODisplay), []];
private _monitorArray_CO = _patient getVariable [QGVAR(AED_CODisplay), []];

for "_i" from 1 to (AED_MONITOR_WIDTH - 1) do { // TODO fix this
    if (_padsState) then {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 0, (_i - 1), (_monitorArray_EKG select (_i - 1)), (_monitorArray_EKG select _i), true] call FUNC(displayAEDMonitor_syncWaveform);
    } else {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 0, (_i - 1), -1, -1, false] call FUNC(displayAEDMonitor_syncWaveform);
    };
    if (_pulseOximeterState) then {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 1, (_i - 1), (_monitorArray_PO select (_i - 1)), (_monitorArray_PO select _i), true] call FUNC(displayAEDMonitor_syncWaveform);
    } else {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 1, (_i - 1), -1, -1, false] call FUNC(displayAEDMonitor_syncWaveform);
    };
    if (_capnographState) then {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 2, (_i - 1), (_monitorArray_CO select (_i - 1)), (_monitorArray_CO select _i), true] call FUNC(displayAEDMonitor_syncWaveform);
    } else {
        [(uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]), 2, (_i - 1), -1, -1, false] call FUNC(displayAEDMonitor_syncWaveform);
    };
};

if (_patient getVariable [QGVAR(AEDMonitorDisplay_PFH), -1] != -1) exitWith {};

private _PFH = [{
    params ["_args", "_idPFH"];
    _args params ["_patient"];

    private _dlg = (uiNamespace getVariable [QGVAR(AEDMonitor_DLG),displayNull]);

    private _padsState = [_patient, "", 1] call FUNC(hasAED);
    private _pulseOximeterState = [_patient, "", 2] call FUNC(hasAED);
    private _capnographState = [_patient, "", 4] call FUNC(hasAED);

    private _oxygenSaturation = _patient getVariable [QGVAR(AED_PulseOximeter_Display), -1];
    private _etco2 = _patient getVariable [QGVAR(AED_CO2_Display), -1];

    private _monitorUpdateStep = (_patient getVariable [QGVAR(AED_UpdateStep), (floor ((CBA_missionTime - (_patient getVariable [QGVAR(AED_StartTime), CBA_missionTime])) mod 6.2304 / 0.0354))]); // x1.18
    private _monitorArray_Offset = _patient getVariable [QGVAR(AED_Offset), 0];

    private _monitorArray_EKG = _patient getVariable [QGVAR(AED_EKGDisplay), []];
    private _monitorArray_PO = _patient getVariable [QGVAR(AED_PODisplay), []];
    private _monitorArray_CO = _patient getVariable [QGVAR(AED_CODisplay), []];

    private _monitorArray_EKGRefresh = _patient getVariable [QGVAR(AED_EKGRefreshDisplay), []];
    private _monitorArray_PORefresh = _patient getVariable [QGVAR(AED_PORefreshDisplay), []];
    private _monitorArray_CORefresh = _patient getVariable [QGVAR(AED_CORefreshDisplay), []];

    private _timeToExpire = (((AED_MONITOR_WIDTH - 1) - _monitorUpdateStep) * 0.03) max 0;

    if (isNull _dlg) exitWith {
        //_patient setVariable [QGVAR(AED_EKGDisplay), _monitorArray_EKGRefresh, true];
        //_patient setVariable [QGVAR(AED_PODisplay), _monitorArray_PORefresh, true];

        _patient setVariable [QGVAR(AED_UpdateStep), nil];
        _patient setVariable [QGVAR(AED_Offset), 0];
        
        _patient setVariable [QGVAR(AEDMonitorDisplay_PFH), -1];

        if (GVAR(AED_ReOpenMenu)) then {
            GVAR(AED_ReOpenMenu) = false;
            [QEGVAR(core,openMedicalMenu), _patient] call CBA_fnc_localEvent;
        };
        
        [_idPFH] call CBA_fnc_removePerFrameHandler;
    };

    private _hr = GET_HEART_RATE(_patient);  // mechanical/perfusion rate
    private _ekgHR = [_patient] call FUNC(getEKGHeartRate);  // electrical rate: same source used by audible AED beep/readout
    private _rhythmState = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];
    private _rr = GET_RESPIRATION_RATE(_patient);
    private _EKGRhythm = ACM_Rhythm_NA;
    private _PORhythm = ACM_Rhythm_NA;
    private _CORhythm = ACM_Rhythm_NA;
    private _EKGStepSpacing = 8;
    private _POStepSpacing = _EKGStepSpacing;
    private _COStepSpacing = _EKGStepSpacing;

    switch (true) do {
        case (alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull]) && _hr > 0): { // CPR
            if (_padsState) then {
                _EKGRhythm = ACM_Rhythm_CPR;
            };
            if (_pulseOximeterState) then {
                _PORhythm = ACM_Rhythm_CPR;
            };
            if (_capnographState) then {
                _CORhythm = ACM_Rhythm_CPR;
            };
            _EKGStepSpacing = if (_ekgHR > 0) then {(60 / _ekgHR) * AED_SPACING_MULTIPLIER} else {0};
            _POStepSpacing = (60 / _hr) * AED_SPACING_MULTIPLIER;
            _COStepSpacing = _POStepSpacing;
        };
        case ([_patient, true] call FUNC(recentAEDShock)): { // After shock
            if (_padsState) then {
                _EKGRhythm = ACM_Rhythm_Asystole;
            };
            if (_pulseOximeterState) then {
                _PORhythm = ACM_Rhythm_Asystole;
            };
            if (_capnographState) then {
                _CORhythm = ACM_Rhythm_Asystole;
            };
            _EKGStepSpacing = 0;
            _POStepSpacing = 0;
            _COStepSpacing = 0;
        };
        case (_hr < 20): {
            _EKGStepSpacing = 0;
            _POStepSpacing = 0;
            _COStepSpacing = 0;
            if (_padsState) then {
                _EKGRhythm = _rhythmState;
                if (_ekgHR > 0) then {
                    _EKGStepSpacing = (60 / _ekgHR) * AED_SPACING_MULTIPLIER;
                };
            };
            if (_pulseOximeterState) then {
                _PORhythm = ACM_Rhythm_Asystole;
            };
            if (_capnographState) then {
                _CORhythm = ACM_Rhythm_Asystole;
            };
        };
        case !(alive _patient): {
            if (_padsState) then {
                _EKGRhythm = ACM_Rhythm_Asystole;
            };
            if (_pulseOximeterState) then {
                _PORhythm = ACM_Rhythm_Asystole;
            };
            if (_capnographState) then {
                _CORhythm = ACM_Rhythm_Asystole;
            };
            _EKGStepSpacing = 0;
            _POStepSpacing = 0;
            _COStepSpacing = 0;
        };
        case (!(HAS_PULSE_P(_patient)) && _hr > 180): { // VT
            if (_padsState) then {
                _EKGRhythm = ACM_Rhythm_VT;
            };
            if (_pulseOximeterState) then {
                if (_oxygenSaturation != -1) then {
                    _PORhythm = ACM_Rhythm_VT;
                } else {
                    _PORhythm = ACM_Rhythm_Asystole;
                };
            };
            if (_capnographState) then {
                if (_etco2 != -1) then {
                    _CORhythm = ACM_Rhythm_VT;
                } else {
                    _CORhythm = ACM_Rhythm_Asystole;
                };
            };
            _EKGStepSpacing = if (_ekgHR > 0) then {(60 / _ekgHR) * AED_SPACING_MULTIPLIER} else {0};
            _POStepSpacing = (60 / _hr) * AED_SPACING_MULTIPLIER;
            _COStepSpacing = _POStepSpacing;
        };
        default { // Sinus
            if (_padsState) then {
                _EKGRhythm = _rhythmState;
            };
            if (_pulseOximeterState) then {
                if (_oxygenSaturation != -1) then {
                    _PORhythm = _rhythmState;
                } else {
                    _PORhythm = ACM_Rhythm_Asystole;
                };
            };
            if (_capnographState) then {
                if (_etco2 != -1) then {
                    _CORhythm = _rhythmState;
                } else {
                    _CORhythm = ACM_Rhythm_Asystole;
                };
            };
            _EKGStepSpacing = if (_ekgHR > 0) then {(60 / _ekgHR) * AED_SPACING_MULTIPLIER} else {0};
            _POStepSpacing = (60 / _hr) * AED_SPACING_MULTIPLIER;
            _COStepSpacing = _POStepSpacing;
        };
    };

    _EKGStepSpacing = 0 max (round(_EKGStepSpacing));
    _POStepSpacing = 0 max (round(_POStepSpacing));
    _COStepSpacing = 0 max (round(_COStepSpacing));

    private _connectedEKG = _patient getVariable [QGVAR(AED_Monitor_Pads_State), false] != _padsState;
    private _connectedPO = _patient getVariable [QGVAR(AED_Monitor_PulseOximeter_State), false] != _pulseOximeterState;
    private _connectedCO = _patient getVariable [QGVAR(AED_Monitor_Capnograph_State), false] != _capnographState;

    private _vitalsEKG = abs (round (_patient getVariable [QGVAR(AED_Monitor_HR), 0]) - round _ekgHR) >= 1;
    private _vitalsPO = abs ((_patient getVariable [QGVAR(AED_Monitor_OxygenSaturation), 0]) - _oxygenSaturation) > 6;
    private _vitalsCO = abs ((_patient getVariable [QGVAR(AED_Monitor_EtCO2), 0]) - _etco2) > 10;

    private _stepCondition = _monitorUpdateStep >= AED_MONITOR_LASTINDEX;
    private _oldEKGRhythm = _patient getVariable [QGVAR(AED_EKGRhythm), -2];
    private _oldPORhythm = _patient getVariable [QGVAR(AED_PORhythm), -2];
    private _oldCORhythm = _patient getVariable [QGVAR(AED_CORhythm), -2];
    private _rhythmChangeEKG = _EKGRhythm != _oldEKGRhythm;
    private _rhythmChangePO = _PORhythm != _oldPORhythm;
    private _rhythmChangeCO = _CORhythm != _oldCORhythm;
    private _rhythmChangeCondition = _rhythmChangeEKG || _rhythmChangePO || _rhythmChangeCO;

    // A real beep is also a clock synchronization point. Regenerate the future EKG strip once after each beep so
    // rate changes cannot leave the audio on a new R-R epoch while the visible buffer is still on the old one.
    private _beatSerial = _patient getVariable ["ACME_AED_BeatSerial", 0];
    private _beatChanged = _beatSerial != (_patient getVariable ["ACME_AED_Monitor_BeatSerial", -1]);

    private _vitalsCondition = _vitalsEKG || _vitalsPO || _vitalsCO;
    private _connectedCondition = _connectedEKG || _connectedPO || _connectedCO;
    private _listCondition = (count _monitorArray_EKGRefresh < AED_MONITOR_WIDTH) || (count _monitorArray_PORefresh < AED_MONITOR_WIDTH) || (count _monitorArray_CORefresh < AED_MONITOR_WIDTH);

    if (_stepCondition || {_beatChanged || {_vitalsCondition || {_rhythmChangeCondition || {_connectedCondition || {_listCondition}}}}}) then {
        _patient setVariable [QGVAR(AED_EKGRhythm), _EKGRhythm];
        _patient setVariable [QGVAR(AED_PORhythm), _PORhythm];
        _patient setVariable [QGVAR(AED_CORhythm), _CORhythm];

        private _generatedEKG = [_EKGRhythm, _EKGStepSpacing, _monitorArray_Offset] call FUNC(displayAEDMonitor_generateEKG);
        private _generatedPO = [_PORhythm, _POStepSpacing, _monitorArray_Offset, _oxygenSaturation] call FUNC(displayAEDMonitor_generatePO);
        private _generatedCO = [_CORhythm, _COStepSpacing, _monitorArray_Offset, _etco2, _rr] call FUNC(displayAEDMonitor_generateCO);

        private _freshEKG = _generatedEKG select 0;
        private _freshPO = _generatedPO select 0;
        private _freshCO = _generatedCO select 0;

        // Blend the currently scheduled continuation into the newly generated SAME screen indices. The previous code
        // copied refresh[0] into screen[current+1], effectively restarting a second ECG timeline in the middle of a
        // sweep. The bridge source must be the existing REFRESH buffer, not the display array: undrawn display indices
        // are stale values from the prior sweep, while refresh is the waveform that was actually about to be drawn.
        // A short value morph therefore preserves endpoint continuity for every rhythm-to-rhythm transition.
        private _fnc_bridge = {
            params ["_current", "_fresh", "_start", "_columns"];
            private _out = +_current;
            if (count _out < AED_MONITOR_WIDTH) then {_out resize [AED_MONITOR_WIDTH, 0];};
            if (count _fresh < AED_MONITOR_WIDTH) exitWith {_out};
            if (_start > AED_MONITOR_LASTINDEX) exitWith {_out};
            private _endBridge = (_start + (_columns max 1) - 1) min AED_MONITOR_LASTINDEX;
            for "_i" from _start to AED_MONITOR_LASTINDEX do {
                private _newValue = _fresh select _i;
                if (_i <= _endBridge) then {
                    private _oldValue = _out select _i;
                    private _alpha = (_i - _start + 1) / ((_endBridge - _start + 1) max 1);
                    _out set [_i, _oldValue + ((_newValue - _oldValue) * _alpha)];
                } else {
                    _out set [_i, _newValue];
                };
            };
            _out
        };

        if (_stepCondition) then {
            // At the right edge the EKG generator anchors index 0 to "now" for the next left-to-right sweep.
            _monitorArray_EKGRefresh = _freshEKG;
            _monitorArray_PORefresh = _freshPO;
            _monitorArray_CORefresh = _freshCO;
            _patient setVariable [QGVAR(AED_EKGRefreshDisplay), _monitorArray_EKGRefresh];
            _patient setVariable [QGVAR(AED_PORefreshDisplay), _monitorArray_PORefresh];
            _patient setVariable [QGVAR(AED_CORefreshDisplay), _monitorArray_CORefresh];
        } else {
            private _startIndex = (_monitorUpdateStep + 1) min AED_MONITOR_LASTINDEX;

            if (_rhythmChangeEKG || {_connectedEKG || {_vitalsEKG || {_beatChanged || {count _monitorArray_EKGRefresh < AED_MONITOR_WIDTH}}}}) then {
                private _bridgeColumns = [4, 8] select _rhythmChangeEKG;
                private _ekgBasis = if (count _monitorArray_EKGRefresh >= AED_MONITOR_WIDTH) then {_monitorArray_EKGRefresh} else {_monitorArray_EKG};
                _monitorArray_EKGRefresh = [_ekgBasis, _freshEKG, _startIndex, _bridgeColumns] call _fnc_bridge;
                _patient setVariable [QGVAR(AED_EKGRefreshDisplay), _monitorArray_EKGRefresh];
            };

            if (_rhythmChangePO || {_connectedPO || {_vitalsPO || {count _monitorArray_PORefresh < AED_MONITOR_WIDTH}}}) then {
                private _poBasis = if (count _monitorArray_PORefresh >= AED_MONITOR_WIDTH) then {_monitorArray_PORefresh} else {_monitorArray_PO};
                _monitorArray_PORefresh = [_poBasis, _freshPO, _startIndex, 4] call _fnc_bridge;
                _patient setVariable [QGVAR(AED_PORefreshDisplay), _monitorArray_PORefresh];
            };

            if (_rhythmChangeCO || {_connectedCO || {_vitalsCO || {count _monitorArray_CORefresh < AED_MONITOR_WIDTH}}}) then {
                private _coBasis = if (count _monitorArray_CORefresh >= AED_MONITOR_WIDTH) then {_monitorArray_CORefresh} else {_monitorArray_CO};
                _monitorArray_CORefresh = [_coBasis, _freshCO, _startIndex, 4] call _fnc_bridge;
                _patient setVariable [QGVAR(AED_CORefreshDisplay), _monitorArray_CORefresh];
            };
        };

        _patient setVariable ["ACME_AED_Monitor_BeatSerial", _beatSerial, false];
        _patient setVariable [QGVAR(AED_Monitor_Pads_State), _padsState];
        _patient setVariable [QGVAR(AED_Monitor_PulseOximeter_State), _pulseOximeterState];
        _patient setVariable [QGVAR(AED_Monitor_Capnograph_State), _capnographState];
        _patient setVariable [QGVAR(AED_Monitor_OxygenSaturation), _oxygenSaturation];
        _patient setVariable [QGVAR(AED_Monitor_EtCO2), _etco2];
        _patient setVariable [QGVAR(AED_Monitor_HR), _ekgHR];

        /*_monitorArray_Offset = _monitorArray_Offset + round (random [-1.4, 0, 1.4]); // TODO look at later
        if (_monitorArray_Offset > 22) then {
            _monitorArray_Offset = 0;
        };*/
        
        //_patient setVariable [QGVAR(AED_Offset), _monitorArray_Offset, true];
    };

    if !(isNull _dlg) then {
        // Fixed-step sweep clock. The old loop advanced only ONE 0.03 s column whenever a render frame happened to
        // arrive after the deadline, then reset the deadline to "now". At 60 FPS that turns 30 ms columns into ~33 ms
        // columns and the trace steadily falls behind real time / the audible beep. Preserve the 30 ms accumulator and
        // draw every due segment; ordinary frames are 0-2 steps, while a hitch simply catches the cursor up in one
        // frame without stretching R-R spacing.
        if !(GVAR(EKG_Tick) isEqualType 0) then {GVAR(EKG_Tick) = CBA_missionTime;};
        private _stepsDue = floor (((CBA_missionTime - GVAR(EKG_Tick)) max 0) / 0.03);
        if (_stepsDue > 0) then {
            // Bound pathological multi-second stalls. A 32-column catch-up is nearly a full second; if the client was
            // paused longer than that, resynchronize the time base after drawing those columns rather than spending
            // several frames running the monitor at fast-forward speed.
            private _rawStepsDue = _stepsDue;
            _stepsDue = _stepsDue min 32;
            for "_s" from 1 to _stepsDue do {
                if (_monitorUpdateStep < AED_MONITOR_LASTINDEX) then {
                    _monitorUpdateStep = _monitorUpdateStep + 1;
                } else {
                    _monitorUpdateStep = 1;
                };

                _patient setVariable [QGVAR(AED_UpdateStep), _monitorUpdateStep];
                [_dlg, _patient, _monitorUpdateStep] call FUNC(displayAEDMonitor_updateStep);
            };
            GVAR(EKG_Tick) = GVAR(EKG_Tick) + (_stepsDue * 0.03);
            if (_rawStepsDue > 32) then {GVAR(EKG_Tick) = CBA_missionTime;};
        };
        
        // Update vitals displays
        private _displayedHR = _patient getVariable [QGVAR(AED_Pads_Display), 0];
        private _displayedSPO2 = _patient getVariable [QGVAR(AED_PulseOximeter_Display), 0];
        private _displayedNIBP = _patient getVariable [QGVAR(AED_NIBP_Display), [0,0]];
        private _displayedRR = _patient getVariable [QGVAR(AED_RR_Display), 0];
        private _displayedCO2 = _patient getVariable [QGVAR(AED_CO2_Display), 0];

        private _displayedNIBP_M = 0;

        if (_displayedHR < 1) then {
            _displayedHR = "---";
        } else {
            _displayedHR = _displayedHR toFixed 0;
        };
        if (_displayedSPO2 < 1) then {
            _displayedSPO2 = "---";
        } else {
            _displayedSPO2 = _displayedSPO2 toFixed 0;
        };

        _displayedNIBP params ["_displayedNIBP_S", "_displayedNIBP_D"];

        if (_displayedNIBP_D < 1 || _displayedNIBP_S < 1) then {
            _displayedNIBP_S = "---";
            _displayedNIBP_D = "---";
            _displayedNIBP_M = "--";
        } else {
            _displayedNIBP_M = GET_MAP(_displayedNIBP_S,_displayedNIBP_D);
            _displayedNIBP_M = _displayedNIBP_M toFixed 0;
            _displayedNIBP_S = _displayedNIBP_S toFixed 0;
            _displayedNIBP_D = _displayedNIBP_D toFixed 0;
        };

        if (_displayedRR < 1 || _displayedCO2 < 1) then {
            _displayedRR = "--";
            _displayedCO2 = "---";
        } else {
            _displayedRR = _displayedRR toFixed 0;
            _displayedCO2 = _displayedCO2 toFixed 0;
        };

        ctrlSetText [IDC_VITALSDISPLAY_HR, _displayedHR];
        ctrlSetText [IDC_VITALSDISPLAY_SPO2, _displayedSPO2];
        ctrlSetText [IDC_VITALSDISPLAY_NIBP_S, _displayedNIBP_S];
        ctrlSetText [IDC_VITALSDISPLAY_NIBP_D, _displayedNIBP_D];
        ctrlSetText [IDC_VITALSDISPLAY_NIBP_M, _displayedNIBP_M];
        ctrlSetText [IDC_VITALSDISPLAY_RR, _displayedRR];
        ctrlSetText [IDC_VITALSDISPLAY_CO2, _displayedCO2];

        private _HRNumber = _dlg displayCtrl IDC_VITALSDISPLAY_HR;
        private _HRText = _dlg displayCtrl IDC_VITALSDISPLAY_HR_TEXT;

        if (!_padsState && _pulseOximeterState) then {
            ctrlSetText [IDC_VITALSDISPLAY_HR_TEXT, "PR (SpO2)"];
            _HRNumber ctrlSetTextColor SPO2_COLOR_M;
            _HRText ctrlSetTextColor SPO2_COLOR_M;
        } else {
            ctrlSetText [IDC_VITALSDISPLAY_HR_TEXT, "HR"];
            _HRNumber ctrlSetTextColor HR_COLOR_M;
            _HRText ctrlSetTextColor HR_COLOR_M;
        };

        if (_capnographState) then {
            ctrlShow [IDC_CO_Scale_Line_0, true];
            ctrlShow [IDC_CO_Scale_Line_1, true];
            ctrlShow [IDC_CO_Scale_Line_2, true];
            ctrlShow [IDC_CO_Scale_Line_3, true];
            ctrlShow [IDC_CO_Scale_Line_4, true];
            ctrlShow [IDC_CO_Scale_Line_5, true];
            ctrlShow [IDC_CO_Scale_Text_0, true];
            ctrlShow [IDC_CO_Scale_Text_50, true];
        } else {
            ctrlShow [IDC_CO_Scale_Line_0, false];
            ctrlShow [IDC_CO_Scale_Line_1, false];
            ctrlShow [IDC_CO_Scale_Line_2, false];
            ctrlShow [IDC_CO_Scale_Line_3, false];
            ctrlShow [IDC_CO_Scale_Line_4, false];
            ctrlShow [IDC_CO_Scale_Line_5, false];
            ctrlShow [IDC_CO_Scale_Text_0, false];
            ctrlShow [IDC_CO_Scale_Text_50, false];
        };
    };
}, 0, [_patient]] call CBA_fnc_addPerFrameHandler;

_patient setVariable [QGVAR(AEDMonitorDisplay_PFH), _PFH];