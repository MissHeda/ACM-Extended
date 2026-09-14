// Two-page debug dispatcher. Page 0 is the screenshot-friendly clinical overview; page 1 is the full engineering/network view.
disableSerialization;

private _page = uiNamespace getVariable ["ACME_debug_page", 0];
_page = (_page max 0) min 1;
uiNamespace setVariable ["ACME_debug_page", _page];

if (_page == 0) exitWith {
    call ACME_fnc_debugMenuClinical;
};

if (isNil {missionNamespace getVariable "ACME_debugMenu_v121B114DetailsCode"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";
    missionNamespace setVariable ["ACME_debugMenu_v121B114DetailsCode", compile _src];
};
call (missionNamespace getVariable ["ACME_debugMenu_v121B114DetailsCode", {}]);
