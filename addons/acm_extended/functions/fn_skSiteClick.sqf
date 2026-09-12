/* Recheck the exact visible site before dispatch. A stale icon must not use a different line. */
params ["_ctrl"];
private _d = ctrlParent _ctrl;
private _p = _d getVariable ["ACME_SK_ReturnPatient", objNull];
if (isNull _p) then {_p = ACE_player;};
(_ctrl getVariable ["ACME_SK_Target", []]) params ["_part", "_site", "", "_vascular"];
if (_vascular) then {
    private _have = if (_site < 0) then {[_p, _part, 0] call ACM_circulation_fnc_hasIO} else {[_p, _part, 0, _site] call ACM_circulation_fnc_hasIV};
    if (!_have) then {_ctrl setVariable ["ACME_SK_Stale", true];};
} else {_ctrl setVariable ["ACME_SK_Stale", false];};
if (_ctrl getVariable ["ACME_SK_Stale", false]) exitWith {
    _ctrl setVariable ["ACME_SK_Stale", false];
    call ACME_fnc_skBuildHotspots;
    ["That access is no longer present.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
};
uiNamespace setVariable ["ACME_SK_SiteIdx", _site];
if (_vascular && {(uiNamespace getVariable ["ACME_SK_SelFlush", ""]) != ""}) exitWith {[_part] call ACME_fnc_skFlushSite;};
[_part] call ACME_fnc_skBeginInjection;
