/* One explicit push reserves a syringe and its actual contents. Never dose from an uncommitted plunger. */
private _context = missionNamespace getVariable ["ACME_infusion_pendingContext", []];
if (_context isEqualTo []) exitWith {};
if ((missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "") exitWith {};
private _mode = _context select 0;
private _drawDisplay = findDisplay 84000;
private _ml = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _size = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Size", 10];

// Commit the exact row that is selected in ACM's backing medication list. The visible ACME row maps one-to-one to
// this list, so this removes the last timing window where a previous draw-session medication could be committed if
// the provider selected a new drug and immediately pulled/injected.
if (!isNull _drawDisplay) then {
    private _medList = _drawDisplay displayCtrl 84006;
    private _sel = if (isNull _medList) then {-1} else {lbCurSel _medList};
    private _selectedMed = if (_sel >= 0) then {_medList lbData _sel} else {""};
    if (_selectedMed != "") then {
        _med = _selectedMed;
        missionNamespace setVariable ["ACM_circulation_SyringeDraw_Medication", _med];
        missionNamespace setVariable ["ACM_circulation_SyringeDraw_MedicationSelected_Index", _sel];
        missionNamespace setVariable ["ACM_circulation_SyringeDraw_MedicationSelected", true];
    };
};

// Syringe stock and filled-syringe payloads are represented to 0.01 mL. Snapshot the plunger at the same precision
// before source debit and bag registration so the amount removed from the vial is exactly the amount put in the bag.
if (finite _ml) then {_ml = (round ((_ml max 0) * 100)) / 100;};
if (_ml <= 0 || {!finite _ml} || {_ml > _size + 0.001}) exitWith {};
if !(_med in (missionNamespace getVariable ["ACME_infusion_allowedMedications", []])) exitWith {};
if (missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false]) exitWith {};
private _hardMax = _size;
if (!isNull _drawDisplay) then {
    private _sessionMax = (["limit", _med, _ml, _drawDisplay] call ACME_fnc_vialSession) min _size;
    private _holder = [ACE_player] call ACME_fnc_vialHolder;
    private _stockMax = if (isNull _holder) then {0} else {[_holder, _med] call ACME_fnc_infusionVialVolume};
    _hardMax = (_sessionMax min _stockMax min _size) max 0;
};
if (_ml > _hardMax + 0.0005) exitWith {
    [_hardMax, _drawDisplay, true] call ACME_fnc_syringeDrawSetAmount;
    [ACE_player, "The syringe was limited to the medication still available in the selected vial. Confirm the dose and inject again."] call ACME_fnc_clinicalNotice;
};
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
private _display = findDisplay 84000;
[0, _display, true] call ACME_fnc_syringeDrawSetAmount;
ACM_circulation_SyringeDraw_MaxDose = 0;
ACM_circulation_SyringeDraw_MedicationSelected_Index = -1;
ACM_circulation_SyringeDraw_Medication = "";
ACM_circulation_SyringeDraw_MedicationSelected = false;
if (!isNull _display) then {
    ["clear", "", 0, _display] call ACME_fnc_vialSession;
    private _medListB25 = _display displayCtrl 84006;
    if (!isNull _medListB25) then {_medListB25 lbSetCurSel -1; _medListB25 ctrlEnable true;};
};
[] call ACME_fnc_infusionRefreshTally;
// Stay in preparation for further draws of this or another medication.
