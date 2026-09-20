/* B48: Prep Infusion uses the same authoritative native medication list as the main Narc Box.
   Do not build a second list from medication names -> guessed vial classnames; that path was able to create
   blank rows when an alias/presentation class did not match the physical vial. */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display || {isNil "ACME_infusion_pendingContext"}) exitWith {};
private _list = _display displayCtrl 84006;
if (isNull _list) exitWith {};

[_display] call ACME_fnc_skMedicationSync;
_list ctrlShow false;

private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _drawn = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
private _allowed = missionNamespace getVariable ["ACME_infusion_allowedMedications", []];
if (_med != "") then {
    private _limit = ["limit", _med, _drawn, _display] call ACME_fnc_vialSession;
    private _hardMax = (ACM_circulation_SyringeDraw_Size min (_limit max 0)) max 0;
    ACM_circulation_SyringeDraw_MaxDose = _hardMax;

    // If shared stock/source changed underneath an already-staged draw, repair amount and artwork together.
    // Never write DrawnAmount alone: that is what makes the native hit-control and visible plunger separate.
    if (_drawn > _hardMax + 0.0001) then {
        [_hardMax, _display, false] call ACME_fnc_syringeDrawSetAmount;
        _drawn = _hardMax;
    };
};
private _busy = (missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "";
private _moving = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false];
// Commit only a settled plunger. Clicking Inject Into Bag while the plunger is still captured used to let the
// native drag loop and the reset path write the controls at the same time.
(_display displayCtrl 84003) ctrlEnable (!_busy && {!_moving} && {_drawn > 0} && {_med in _allowed});
[_display] call ACME_fnc_skMedicationStockRefresh;
[] call ACME_fnc_infusionRefreshTally;
