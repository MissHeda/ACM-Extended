/* One explicit push reserves a syringe and its actual contents. Never dose from an uncommitted plunger. */
private _context = missionNamespace getVariable ["ACME_infusion_pendingContext", []];
if (_context isEqualTo []) exitWith {};
if ((missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "") exitWith {};
private _mode = _context select 0;
private _ml = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _size = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Size", 10];
if (_ml <= 0 || {!finite _ml} || {_ml > _size + 0.001}) exitWith {};
if !(_med in (missionNamespace getVariable ["ACME_infusion_allowedMedications", []])) exitWith {};
private _drawDisplay = findDisplay 84000;
if (!isNull _drawDisplay && {_ml > (["limit", _med, _ml, _drawDisplay] call ACME_fnc_vialSession) + 0.0005}) exitWith {};
private _concentration = getNumber (configFile >> "ACM_Medication" >> "Concentration" >> _med >> "concentration");
if (_concentration <= 0) exitWith {};
private _ctx = _context select [1, 11];
private _valid = false;
if (_mode == "prepared") then {
    private _sid = _context param [20, ""];
    _valid = _sid != "" && {((ACE_player getVariable ["ACME_preparedIVSets", []]) findIf {(_x select 0) == _sid}) >= 0};
} else {
    _valid = [_ctx] call ACME_fnc_canMedicateBagContext;
    _ctx pushBack (_context param [21, ""]);
};
if (!_valid) exitWith {[ACE_player, "The selected bag is no longer available."] call ACME_fnc_clinicalNotice;};
private _receipt = [ACE_player, _med, _ml, _size] call ACME_fnc_infusionTakeSupplies;
if (_receipt isEqualTo []) exitWith {[ACE_player, "Insufficient medication solution or an empty syringe is missing."] call ACME_fnc_clinicalNotice;};
private _ok = true;
if (_mode == "prepared") then {
    _ok = [_context, _med, _ml * _concentration, _ml] call ACME_fnc_registerPreparedBag;
    if (!_ok) then {[_receipt] call ACME_fnc_infusionRefundSupplies;};
} else {
    private _request = [_ctx, _med, _ml * _concentration, -1, -1, -1, -1, _receipt, _ml] call ACME_fnc_registerBagMedication;
    _ok = _request != "";
    if (!_ok) then {[_receipt] call ACME_fnc_infusionRefundSupplies;};
};
if (!_ok) exitWith {};
ACM_circulation_SyringeDraw_DrawnAmount = 0;
ACM_circulation_SyringeDraw_Moving = false;
private _display = findDisplay 84000;
if (!isNull _display) then {
    ["clear", "", 0, _display] call ACME_fnc_vialSession;
    private _medListB25 = _display displayCtrl 84006;
    if (!isNull _medListB25) then {_medListB25 lbSetCurSel -1; _medListB25 ctrlEnable true;};
    ACM_circulation_SyringeDraw_Medication = "";
    ACM_circulation_SyringeDraw_MedicationSelected = false;
    private _top = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitTop", 0];
    private _offset = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerAdjustment", 0];
    private _visual = _display displayCtrl (missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerVisual", 84010]);
    private _hit = _display displayCtrl 84009;
    if (!isNull _hit) then {private _p = ctrlPosition _hit; _p set [1,_top]; _hit ctrlSetPosition _p; _hit ctrlCommit 0;};
    if (!isNull _visual) then {private _p = ctrlPosition _visual; _p set [1,_top - _offset]; _visual ctrlSetPosition _p; _visual ctrlCommit 0;};
};
[] call ACME_fnc_infusionRefreshTally;
// Stay in preparation for further draws of this or another medication.
