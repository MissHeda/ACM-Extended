// On-demand snapshot. Returns and stores local data; does not write patient state or the RPT.
private _out = [];
/* Read-only clinical/config diagnostic. Run locally from an enabled debug console:
   [] execVM "\acm_extended\tools\na8_runtime_probe.sqf";
   Output is written to the local RPT. No treatment, inventory or network writes. */
disableSerialization;
_out pushBack format ["[ACME NA8 PROBE] version config=%1 runtime=%2", getText (configFile >> "CfgPatches" >> "ACM_Extended" >> "version"), missionNamespace getVariable ["ACME_infusion_version", "missing"]];
private _cfg = configFile >> "ACM_circulation_SyringeDraw_Dialog" >> "Controls";
{
    private _c = _cfg >> _x;
    _out pushBack format ["[ACME NA8 PROBE] button %1 parent=%2 idc=%3 type=%4 sound=%5 callback=%6", _x, configName (inheritsFrom _c), getNumber (_c >> "idc"), getNumber (_c >> "type"), getArray (_c >> "soundClick"), getText (_c >> "onButtonClick")];
} forEach ["Button_Draw", "Button_Inject", "Button_Push"];
_out pushBack format ["[ACME NA8 PROBE] medication label=%1", getText (configFile >> "ACE_Medical_Menu" >> "Controls" >> "Medication" >> "tooltip")];
private _rows = missionNamespace getVariable ["ace_medical_gui_actions", []];
{
    if ((_x param [1, ""]) in ["medication", "airway", "advanced"]) then {
        _out pushBack format ["[ACME NA8 PROBE] action name=%1 category=%2 class=%3 bucket=%4", _x param [0, ""], _x param [1, ""], _x param [8, ""], _x param [9, ""]];
    };
} forEach _rows;
private _d = findDisplay 84000;
if (!isNull _d) then {
    private _p = _d getVariable ["ACME_SK_ReturnPatient", objNull];
    _out pushBack format ["[ACME NA8 PROBE] Narc patient=%1 view=%2 route=%3 drawRect=%4 saveRect=%5", _p, uiNamespace getVariable ["ACME_SK_View", ""], uiNamespace getVariable ["ACME_SK_Route", ""], ctrlPosition (_d displayCtrl 84003), ctrlPosition (_d displayCtrl 84004)];
    private _group = _d displayCtrl 84140;
    {
        if (ctrlShown _x) then {
            _out pushBack format ["[ACME NA8 PROBE] visible idc=%1 class=%2 text=%3", ctrlIDC _x, ctrlClassName _x, ctrlText _x];
        };
    } forEach allControls _group;
    {
        _x params ["_name", "", "", "", "_inputID"];
        private _input = _d displayCtrl _inputID;
        _out pushBack format ["[ACME NA8 PROBE] vascular=%1 shown=%2 enabled=%3 rect=%4", _name, ctrlShown _input, ctrlEnabled _input, ctrlPosition _input];
    } forEach (call ACME_fnc_skSiteGeometry);
};
_out pushBack "[ACME NA8 PROBE] END. A source snapshot does not establish correct in-game behavior.";

missionNamespace setVariable ["ACME_uiProbeResult", _out, false];
_out
