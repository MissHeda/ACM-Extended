// press the safety button and withdraw the needle.
// call it as [] call ACME_fnc_ivMinigameRetract. it only fires once the catheter is fully hubbed.
// frames 12 to 14 run on their own, because pressing the button is one action and the barrel does the rest.
// this is the point where the line is registered and the persistent hub appears.
disableSerialization;
if !([] call ACME_fnc_ivUiValid) exitWith {false};
private _dlg0 = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg0) exitWith {false};
private _stage0 = uiNamespace getVariable ["ACME_IV_InsStage", ""];
if (_stage0 != "thread") exitWith {
    // silence here is indistinguishable from a dead button, which is exactly how this read for three builds.
    if (!isNull _dlg0 && {_stage0 == "advance"}) then {
        (_dlg0 displayCtrl 86503) ctrlSetText "Push the catheter fully in first.";
    };
    false
};
if ((uiNamespace getVariable ["ACME_IV_InsFrame", 6]) < 11) exitWith {
    if (!isNull _dlg0) then {
        (_dlg0 displayCtrl 86503) ctrlSetText "Thread the catheter all the way off the needle first.";
    };
    false
};

uiNamespace setVariable ["ACME_IV_InsStage", "retract"];
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (!isNull _dlg) then { (_dlg displayCtrl 86503) ctrlSetText ""; };

private _context = [_dlg0, +(uiNamespace getVariable ["ACME_IV_Session", []]),
    _dlg0 getVariable ["ACME_IV_ViewGeneration", 0],
    uiNamespace getVariable ["ACME_IV_BodyPart", ""], uiNamespace getVariable ["ACME_IV_View", ""]];
private _handler = [{
    params ["_args", "_h"];
    _args params ["_i", "_context"];
    if !(_context call ACME_fnc_ivMinigameViewValid) exitWith {[_h] call CBA_fnc_removePerFrameHandler;};
    private _dlg = _context select 0;
    private _cath = uiNamespace getVariable ["ACME_IV_CathCtrl", controlNull];
    if (isNull _dlg || {(uiNamespace getVariable ["ACME_IV_InsStage", ""]) != "retract"}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
    };
    if (!isNull _cath) then {
        [_cath, ([(uiNamespace getVariable ["ACME_IV_InsGauge", 16]),
                            (uiNamespace getVariable ["ACME_IV_InsSuffix", ""]), _i] call ACME_fnc_ivCathTex)] call ACME_fnc_ivCathSetFrame;
    };
    if (_i >= 13) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        _dlg setVariable ["ACME_IV_RetractPFH", -1];
        // the needle is out. commit the line, drop the persistent hub and hand over the tubing.
        [(uiNamespace getVariable ["ACME_IV_InsU", 0.5]),
         (uiNamespace getVariable ["ACME_IV_InsV", 0.5])] call ACME_fnc_ivMinigameStickSuccess;
    };
    _args set [0, _i + 1];
}, 0.12, [12, _context]] call CBA_fnc_addPerFrameHandler;
_dlg0 setVariable ["ACME_IV_RetractPFH", _handler];
true
