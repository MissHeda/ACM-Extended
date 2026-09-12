// the syringe-size selection. ACM bakes the size in at open, so we switch by re-opening the dialog of ACM at the
// chosen size, which re-runs its texture and plunger-limit switch, and re-injecting our lists.
// _this, from LBSelChanged, is [_ctrl, _index].
params ["_ctrl", "_index"];
if (_index < 0) exitWith {};
private _size = _ctrl lbValue _index;
if (_size <= 0) exitWith {};
if (([ACE_player, format ["ACM_Syringe_%1", _size]] call ace_common_fnc_getCountOfItem) < 1) exitWith {};
private _saveFailed = false;
private _autoSaved = false;
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) == "compound" && {!((uiNamespace getVariable ["ACME_SK_CompoundComponents", []]) isEqualTo [])}) then {
    _autoSaved = call ACME_fnc_skCompoundCommit;
    _saveFailed = !_autoSaved;
};
if (_saveFailed) exitWith {};
if (_autoSaved) then {call ACME_fnc_skPendingTagReset;};

// if a saline flush is mid-waste, selecting any syringe size, even 10 ml, the own size of the flush, must leave the
// waste flow and give a fresh syringe. so end the waste flow first, and skip the same-size shortcut in that case,
// because otherwise picking 10 ml after a flush read as already 10 ml and did nothing.
private _inWaste = (uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "";
if (_inWaste) then { [] call ACME_fnc_skWasteEnd; };
if (!_inWaste && {_size == (uiNamespace getVariable ["ACME_SK_CurSize", 10])}) exitWith {};  // already this size

private _patient  = uiNamespace getVariable ["ACME_SK_Patient", objNull];
private _bodyPart = uiNamespace getVariable ["ACME_SK_BodyPart", ""];

// re-opening the dialog of ACM recenters the cursor. stash where it is so skOpenDraw can put it back, keeping the
// pointer over the size list instead of snapping it to the screen edge on every size switch.
uiNamespace setVariable ["ACME_SK_RestoreMouse", getMousePosition];

closeDialog 0;
[{ _this call ACME_fnc_skOpenDraw; }, [_size, _patient, _bodyPart], 0.05] call CBA_fnc_waitAndExecute;
