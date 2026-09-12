// Owner-side chest scenarios use the shared PTX model. "ncd" is the instructor's
// explicit clear-chest/reset command, not the clinical needle-decompression action.
// _this is [_patient, _type], run where _patient is local.
// _type is "pneumo", "tpneumo", "hemothorax" or "ncd".
params ["_p", "_type"];
if (isNull _p || {!local _p}) exitWith {};
private _t = toLower _type;

if (_t == "ncd") exitWith {
    private _nativePFH = _p getVariable ["ACM_breathing_Pneumothorax_PFH", -1];
    if (_nativePFH >= 0) then {[_nativePFH] call CBA_fnc_removePerFrameHandler;};
    [_p, [["pneumothoraxPFH", -1]], false] call ACM_breathing_fnc_setRuntimeState;
    {_p setVariable [_x, nil, true];} forEach ["ACME_ptx_state", "ACME_ptx_tensionSeverity", "ACME_ptx_tensionProgress", "ACME_ptx_nativeSealCount", "ACME_ptx_nativeSealHoleCount"];
    _p setVariable ["ACME_alt_ptxSample", nil, false];
    [_p, [["pneumothorax", 0], ["tensionPneumothorax", false], ["clearTensionTime", true], ["hardcorePneumothorax", false], ["hemothorax", 0]], true] call ACM_breathing_fnc_setRuntimeState;
    [_p, false] call ACM_breathing_fnc_setChestInjuryState;
    if (!isNil "ACM_breathing_fnc_updateLungState") then { [_p] call ACM_breathing_fnc_updateLungState; };
};

[_p, true] call ACM_breathing_fnc_setChestInjuryState;
switch (_t) do {
    case "pneumo": {
        [_p] call ACME_fnc_ptxInjury;
    };
    case "tpneumo": {
        [_p] call ACME_fnc_ptxInjury;
        private _ptx = +(_p getVariable ["ACME_ptx_state", []]);
        if (count _ptx == 9) then {
            _ptx set [1, 4];
            _ptx set [3, 0];
            _ptx set [4, 1];
            _ptx set [7, 4];
            [_p, _ptx, true] call ACME_fnc_ptxPublish;
        };
    };
    case "hemothorax": {
        [_p, [["hemothorax", (5 + round (random 5))]], true] call ACM_breathing_fnc_setRuntimeState;
        if (!isNil "ace_medical_fnc_adjustPainLevel") then { [_p, 1] call ace_medical_fnc_adjustPainLevel; };
        if (!isNil "ACM_breathing_fnc_handleHemothorax") then { [_p] call ACM_breathing_fnc_handleHemothorax; };
    };
};
if (!isNil "ACM_breathing_fnc_updateLungState") then { [_p] call ACM_breathing_fnc_updateLungState; };
