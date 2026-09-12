// toggle grabbing the plunger during the flush waste and draw flow.
// it mirrors ACM_circulation_fnc_Syringe_Draw_Move, and is gated on our waste stage rather than on a selected
// medication, because a flush has no drug selected while wasting.
// clicking the plunger grabs it, and the per-frame loop then tracks the mouse, and clicking again releases it.
// call ACME_fnc_skWasteToggleMove.
private _stage = uiNamespace getVariable ["ACME_SK_WasteStage", ""];
if (_stage == "") exitWith {};

private _moving = !(uiNamespace getVariable ["ACME_SK_WasteMoving", false]);
uiNamespace setVariable ["ACME_SK_WasteMoving", _moving];

disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};
private _plunger = _dlg displayCtrl 84009;
if (!isNull _plunger) then {
    _plunger ctrlSetTooltip (["Click to grab the plunger", ""] select _moving);
};
