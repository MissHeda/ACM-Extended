// take a saline line from the tray.
// call it as [] call ACME_fnc_ivMinigameGrabLine. clicking the slot again puts it back.
// the line carries no count, in the same way the pad does, because tubing comes with the catheter.
// it only does anything useful once a catheter is seated, so it says so rather than going quiet.
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg) exitWith {};
// the slot is off by default. see fn_ivminigameinit.
if (!(missionNamespace getVariable ["ACME_iv_lineSlot", false])) exitWith {};
private _held = uiNamespace getVariable ["ACME_IV_Held", "none"];

// clicking the slot while already holding it is a return.
if (_held == "line") exitWith {
    uiNamespace setVariable ["ACME_IV_Held", "none"];
    private _heldC = uiNamespace getVariable ["ACME_IV_HeldCursorCtrl", controlNull];
    if (!isNull _heldC) then { _heldC ctrlShow false; };
    (_dlg displayCtrl 86503) ctrlSetText "";
    [] call ACME_fnc_ivMinigameRefreshBandSlot;
};

// a needle in the middle of going in must not be dropped to pick up tubing.
if ((uiNamespace getVariable ["ACME_IV_InsStage", ""]) in ["advance", "thread", "retract"]) exitWith {
    (_dlg displayCtrl 86503) ctrlSetText "Finish the catheter first.";
};

// find a seated hub on this limb and view that has no line on it yet, and take its orientation.
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
private _suffix = "";
private _angle = 0;
private _found = false;
if (!isNull _patient) then {
    {
        _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""], ["_mframe", ""]];
        if (_mbp == _bp && {_mview == _view} && {_mkind == "hub"} && {_mtex == ""}) exitWith {
            _suffix = _mframe;
            _angle = _x param [13,0];
            _found = true;
        };
    } forEach (_patient getVariable ["ACME_IV_Marks", []]);
};
if (!_found) exitWith {
    (_dlg displayCtrl 86503) ctrlSetText "Nothing to connect it to yet.";
};

uiNamespace setVariable ["ACME_IV_Held", "line"];
uiNamespace setVariable ["ACME_IV_InsSuffix", _suffix];
uiNamespace setVariable ["ACME_IV_InsAngle", _angle];
(_dlg displayCtrl 86503) ctrlSetText "Connect the line to the hub.";
[] call ACME_fnc_ivMinigameRefreshBandSlot;
