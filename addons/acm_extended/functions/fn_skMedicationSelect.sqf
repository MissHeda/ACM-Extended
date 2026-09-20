/* B48: bind the physical vial session when the medic selects a row in ACM's native medication listbox. */
disableSerialization;
params ["_list", "_index"];
if (isNull _list || {_index < 0}) exitWith {};
private _display = findDisplay 84000;
if (isNull _display) exitWith {};
private _med = _list lbData _index;
if (_med == "") exitWith {};

// The visible ACME medication row drives ACM's hidden backing list. Do not wait for ACM's next per-frame pass
// to publish the selected medication into the syringe session: a fast click-and-pull could otherwise keep the
// previous medication identity/max dose for one frame. Bind the exact selected row immediately, matching the
// normal Narc Box source identity before the plunger can move.
missionNamespace setVariable ["ACM_circulation_SyringeDraw_Medication", _med];
missionNamespace setVariable ["ACM_circulation_SyringeDraw_MedicationSelected_Index", _index];
missionNamespace setVariable ["ACM_circulation_SyringeDraw_MedicationSelected", true];

private _stage = uiNamespace getVariable ["ACME_SK_WasteStage", ""];
if (_stage in ["compound","draw"] && {uiNamespace getVariable ["ACME_SK_WasteMoving", false]}) exitWith {};

private _holder = [ACE_player] call ACME_fnc_vialHolder;
if (isNull _holder) exitWith {};
private _rows = _display getVariable ["ACME_SK_MedicationRows", []];
private _ri = _rows findIf {(_x param [1, ""]) == _med};
private _physicalClass = if (_ri >= 0) then {(_rows select _ri) param [3, ""]} else {""};
private _preview = [_holder, _med, 0, _physicalClass] call ACME_fnc_vialPreview;
if ((_preview param [3, 0]) <= 0.000001) exitWith {};

private _reserved = 0;
if (_stage in ["compound","draw"]) then {
    {
        if ((_x param [0, ""]) == _med) then {_reserved = _reserved + (_x param [1, 0]);};
    } forEach (uiNamespace getVariable ["ACME_SK_CompoundComponents", []]);
    if ((missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""]) == _med) then {
        _reserved = _reserved + (((uiNamespace getVariable ["ACME_SK_WasteFill", 0])
            - (uiNamespace getVariable ["ACME_SK_WasteFloorMl", 0])) max 0);
    };
} else {
    if ((missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""]) == _med) then {
        _reserved = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
    };
};

private _selectedLimit = ["select", _med, _reserved, _display] call ACME_fnc_vialSession;
private _size = (missionNamespace getVariable ["ACM_circulation_SyringeDraw_Size", 10]) max 0.1;
missionNamespace setVariable ["ACM_circulation_SyringeDraw_MaxDose", (_selectedLimit max 0) min _size];
[_display] call ACME_fnc_skMedicationStockRefresh;
