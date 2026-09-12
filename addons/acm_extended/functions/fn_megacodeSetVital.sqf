// set one panel-authoritative vital on the megacode dummy from a slider.
// the monitored vitals, the hr, SpO2, bp, rr and EtCO2, are written as targets. the server keeper,
// ACME_fnc_megacodeWatch, then eases the live value toward the target each second, so a slider press ramps the
// number over instead of snapping it, LifePak-like.
// we also push into the ACM and ACE sim where a real driver exists, so the downstream behavior, such as the CPR
// thresholds, tracks.
// _this is [_key, _val].
params ["_key", "_val"];
private _d = uiNamespace getVariable ["ACME_MC_target", objNull];
if (isNull _d) exitWith {};
switch (toUpper _key) do {
    case "HR":   { _d setVariable ["ACME_MC_HRTgt", _val, true];   [_d, [["heartRate", _val]], true] call ACM_core_fnc_setTargetVitalsState; };
    case "SPO2": { _d setVariable ["ACME_MC_SpO2Tgt", _val, true]; [_d, [["oxygenSaturation", _val]], true] call ACM_core_fnc_setTargetVitalsState; [_d, [["spo2", _val, true]]] call ACM_core_fnc_setAceMedicalState; };
    case "SBP":  { _d setVariable ["ACME_MC_SBPTgt", _val, true]; };
    case "DBP":  { _d setVariable ["ACME_MC_DBPTgt", _val, true]; };
    case "RR":   { _d setVariable ["ACME_MC_RRTgt", _val, true];   [_d, [["respirationRate", _val]], true] call ACM_core_fnc_setTargetVitalsState; [_d, [["respirationRate", _val]], true] call ACM_breathing_fnc_setRuntimeState; };
    case "ETCO2":{ _d setVariable ["ACME_MC_EtCO2Tgt", _val, true]; };
    case "TEMP": { _d setVariable ["ACME_MC_Temp", (_val / 10), true]; [_d, [["bodyTemperature", (_val / 10), true]]] call ACM_core_fnc_setAceMedicalState; };
    case "ICP":  {
        _d setVariable ["ACME_MC_ICP", _val, true];
        // a rising ICP drives a live cushing reflex: bradycardia plus hypertension. these set targets too, so the cushing
        // response ramps in smoothly. it is only applied once the ICP is genuinely elevated, above 20.
        if (_val > 20) then {
            private _sev = linearConversion [20, 55, _val, 0, 1, true];
            _d setVariable ["ACME_MC_HRTgt", round (80 - (_sev * 42)), true];
            [_d, [["heartRate", round (80 - (_sev * 42))]], true] call ACM_core_fnc_setTargetVitalsState;
            _d setVariable ["ACME_MC_SBPTgt", round (120 + (_sev * 85)), true];
            _d setVariable ["ACME_MC_DBPTgt", round (78 + (_sev * 42)), true];
        };
    };
    case "GCS":  {
        _d setVariable ["ACME_MC_GCS", _val, true];
        // a GCS below 9 is unconscious and 9 or above is awake. it drives real ACE consciousness on the owner of the
        // dummy.
        private _wantUncon = (_val < 9);
        if (_wantUncon != (_d getVariable ["ACE_isUnconscious", false])) then {
            [_d, _wantUncon] remoteExec ["ace_medical_status_fnc_setUnconsciousState", _d];
        };
    };
};
