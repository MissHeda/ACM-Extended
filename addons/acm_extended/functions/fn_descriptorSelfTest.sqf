// Check wording in the currently selected mode. Run again after changing the checkbox to test the other mode.
// This function never writes a CBA setting, a cached mode flag, patient state, or the RPT.
// Returns [checkCount, failures]. Full samples remain in local ACME_descriptorSelfTestResult.
params [["_target", objNull, [objNull]]];
private _enabled = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
private _checks = 0;
private _fails = [];
private _samples = [];
private _check = {
    params ["_name", "_ok", ["_detail", ""]];
    _checks = _checks + 1;
    if (!_ok) then {_fails pushBack format ["%1: %2", _name, _detail];};
};
["CBA checkbox exists", !isNil "ACME_hc_descriptors"] call _check;
["CBA checkbox is Boolean", (missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualType true] call _check;

{
    private _part = _x;
    {
        private _site = _forEachIndex;
        private _siteText = _x;
        private _row = [_part, _site] call ACME_fnc_ivVeinCatalog;
        private _want = if (_enabled) then {_row getOrDefault ["name", ""]}
            else {["Upper", "Middle", "Lower"] select _site};
        private _numeric = [_part, _site, false] call ACME_fnc_skSiteName;
        private _named = [_part, _siteText, false] call ACME_fnc_skSiteName;
        [format ["site %1/%2", _part, _siteText], _numeric isEqualTo _want && {_named isEqualTo _want}, _named] call _check;
        _samples pushBack ["site", _part, _siteText, _named];
    } forEach ["upper", "middle", "lower"];
} forEach ["leftarm", "rightarm", "leftleg", "rightleg"];

{
    _x params ["_name", "_plain", "_clinical"];
    private _got = ["breathing", _name] call ACME_fnc_medDescriptor;
    private _want = [_plain, _clinical] select _enabled;
    ["breathing " + _name, _got isEqualTo _want, _got] call _check;
    _samples pushBack ["breathing", _name, _got];
} forEach [
    ["normal", "Breathing normally", "Eupneic, equal chest rise"],
    ["slow", "Breathing slowly", "Bradypneic"],
    ["fast", "Breathing quickly", "Tachypneic"],
    ["none", "Not breathing", "Apneic"],
    ["apneic", "Patient is not breathing", "Patient is apneic"],
    ["apneicShort", "None", "Apneic"],
    ["tachyShallow", "Patient breathing is rapid and shallow", "Patient is tachypneic with shallow respirations"]
];

{
    private _got = [_x] call ACME_fnc_clinTerm;
    ["clinical key " + _x, if (_enabled) then {_got isNotEqualTo ""} else {_got isEqualTo ""}, _got] call _check;
    _samples pushBack ["term", _x, _got];
} forEach [
    "STR_ACM_Breathing_CheckBreathing_None", "STR_ACM_Breathing_CheckBreathing_Rapid",
    "STR_ACM_Breathing_CheckBreathing_Slow", "STR_ACM_Breathing_CheckBreathing_Normal",
    "STR_ACM_Breathing_InspectChest_Bruising", "STR_ACM_Airway_CheckAirway_Inflammation_Severe",
    "STR_ACE_Medical_Treatment_Check_Response_Dead", "STR_ACE_Medical_Treatment_Check_Pulse_Weak",
    "STR_ACM_Disability_InspectForFracture_Swelling", "STR_ACM_Disability_InspectForFracture_Bruised"
];

{
    _x params ["_part", "_site", "_index"];
    private _token = format ["(%1)", localize "STR_ACM_Circulation_IV_Middle"];
    private _original = "20g IV " + _token + " [Saline]";
    private _got = [_original, _index, false] call ACME_fnc_ivSiteRelabel;
    private _name = ([_part, _site] call ACME_fnc_ivVeinCatalog) getOrDefault ["name", ""];
    private _want = if (_enabled) then {"20g IV (" + _name + ") [Saline]"} else {_original};
    ["anatomical row " + _part, _got isEqualTo _want, _got] call _check;
    _samples pushBack ["row", _got];
} forEach [["leftarm", 1, 2], ["rightarm", 1, 3], ["leftleg", 1, 4], ["rightleg", 1, 5]];

// Both extended gauges on one limb must resolve independently, before any anatomical relabel.
private _upper = localize "STR_ACM_Circulation_IV_Upper";
private _lower = localize "STR_ACM_Circulation_IV_Lower";
private _entries = [
    ["true (" + _upper + ") [Blood]", [1, 1, 1, 1]],
    ["true (" + _lower + ")", [1, 1, 1, 1]]
];
[_entries, [6, 0, 5]] call ACME_fnc_ivGaugeRelabel;
["20g row", ((_entries select 0) select 0) isEqualTo ("20g IV (" + _upper + ") [Blood]")] call _check;
["18g row", ((_entries select 1) select 0) isEqualTo ("18g IV (" + _lower + ")")] call _check;

["mode unchanged", _enabled isEqualTo ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true)] call _check;
missionNamespace setVariable ["ACME_descriptorSelfTestResult", [_enabled, _checks, +_fails, +_samples], false];
if (hasInterface && {!isNil "ace_common_fnc_displayTextStructured"}) then {
    private _msg = format ["Descriptor check (%1): %2 checks, %3 failed.<br/>Local details: ACME_descriptorSelfTestResult.",
        ["OFF", "ON"] select _enabled, _checks, count _fails];
    [_msg, 4] call ace_common_fnc_displayTextStructured;
};
[_checks, _fails]
