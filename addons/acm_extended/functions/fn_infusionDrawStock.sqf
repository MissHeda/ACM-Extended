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

    // Never allow infusion prep's state to get ahead of the physical vial even for one UI frame. skUiTick owns
    // the continuous physical stop; this is the commit-side belt-and-suspenders clamp for the first pull.
    if (_drawn > _hardMax + 0.0001) then {
        ACM_circulation_SyringeDraw_DrawnAmount = _hardMax;
        _drawn = _hardMax;
    };
};
private _busy = (missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "";
(_display displayCtrl 84003) ctrlEnable (!_busy && {_drawn > 0} && {_med in _allowed});
[_display] call ACME_fnc_skMedicationStockRefresh;
[] call ACME_fnc_infusionRefreshTally;
