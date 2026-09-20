/* Prep Infusion stock/tally refresh.
 *
 * Syringe movement is intentionally NOT implemented here. Prep Infusion runs ACME_fnc_skCompoundBegin and therefore
 * uses the exact same proven plunger PFH as the Narc Box. Keeping one writer for cursor position, plunger artwork and
 * SyringeDraw_DrawnAmount prevents the 1 mL / 0.2 mL disagreement caused by two independent draw loops.
 */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display || {isNil "ACME_infusion_pendingContext"}) exitWith {};
private _list = _display displayCtrl 84006;
if (isNull _list) exitWith {};

[_display] call ACME_fnc_skMedicationSync;
_list ctrlShow false;

private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _drawn = uiNamespace getVariable ["ACME_SK_WasteFill", missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0]];
if (!finite _drawn) then {_drawn = 0;};
private _allowed = missionNamespace getVariable ["ACME_infusion_allowedMedications", []];
private _busy = (missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "";
private _moving = uiNamespace getVariable ["ACME_SK_WasteMoving", false];

// Inject only after the same Narc Box plunger has been released and contains a positive amount.
(_display displayCtrl 84003) ctrlEnable (!_busy && {!_moving} && {_drawn > 0.0005} && {_med in _allowed});
[_display] call ACME_fnc_skMedicationStockRefresh;
[] call ACME_fnc_infusionRefreshTally;
