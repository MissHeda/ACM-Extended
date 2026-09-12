// the "Waste" button. the plunger is wherever the medic dragged it, and the saline remaining is drawnamount, in ml.
// lock that as the floor so the plunger can no longer go above it, meaning you cannot un-waste, ungray the drug
// menu, and flip the button to "Draw" so a drug can be pulled on top of the remaining saline, up to the wasted
// volume. it is one waste, once and done.
// call ACME_fnc_skWasteCommit.
disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "waste") exitWith {};

private _cap = uiNamespace getVariable ["ACME_SK_WasteCap", 10];
private _remaining = ((uiNamespace getVariable ["ACME_SK_WasteFill", ACM_circulation_SyringeDraw_DrawnAmount]) max 0) min _cap;
private _wasted = _cap - _remaining;

if (_wasted <= 0.05) exitWith {
    ["Waste some saline first: click the plunger and drag it up.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// release the plunger grab and lock the floor at the remaining saline.
uiNamespace setVariable ["ACME_SK_WasteMoving", false];
uiNamespace setVariable ["ACME_SK_WasteFloorMl", _remaining];
uiNamespace setVariable ["ACME_SK_WasteNS", _remaining];  // remembered for the label
uiNamespace setVariable ["ACME_SK_WasteStage", "draw"];

// ungray the drug menu.
private _medList = _dlg displayCtrl 84006;
if (!isNull _medList) then { _medList ctrlEnable true; };
private _medListBtn = _dlg displayCtrl 84007;
if (!isNull _medListBtn) then { _medListBtn ctrlEnable true; };

// Draw now locks one medication component exactly like a normal compound syringe. Save commits the flush,
// remaining saline and every locked component as one source-funded prepared syringe.
private _btn = _dlg displayCtrl 84003;
if (!isNull _btn) then {
    _btn ctrlSetText "Draw";
    _btn ctrlSetTooltip "Select a drug, draw it into the flush, then press Draw. Repeat for more medications.";
    _btn ctrlEnable true;
    _btn ctrlSetEventHandler ["ButtonClick", "call ACME_fnc_skWasteDraw"];
    _btn ctrlCommit 0;
};
private _save = _dlg displayCtrl 84004;
if (!isNull _save) then {
    _save ctrlShow true;
    _save ctrlEnable true;
    _save ctrlSetText "Save";
    _save ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];
    _save ctrlSetTooltip "Save the medicated saline flush to the Syringe Menu";
    _save ctrlSetEventHandler ["ButtonClick", "call ACME_fnc_skFlushSave"];
    _save ctrlCommit 0;
};

