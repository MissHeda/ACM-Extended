// the narc box body-map flush: flush the clicked iv or io site with a prefilled 10 ml saline flush.
// this is separate from a syringe injection. it delivers only the pending push meds parked in that line and site,
// and leaves pending meds parked in other iv and io sites untouched.
params ["_bodyPart"];

private _display = findDisplay 84000;
private _patient = uiNamespace getVariable ["ACME_SK_Patient", objNull];
if (isNull _patient) then { _patient = ACE_player; };

private _flushClass = uiNamespace getVariable ["ACME_SK_SelFlush", "ACM_SalineFlush_10"];
if (_flushClass isEqualTo "") then { _flushClass = "ACM_SalineFlush_10"; };

if (([ACE_player, _flushClass] call ace_common_fnc_getCountOfItem) < 1) exitWith {
    ["No 10 mL saline flush in inventory.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    uiNamespace setVariable ["ACME_SK_SelFlush", ""];
    call ACME_fnc_skBuildHotspots;
};

private _hasLine = ([_patient, _bodyPart, 0] call ACM_circulation_fnc_hasIV) || {[_patient, _bodyPart, 0] call ACM_circulation_fnc_hasIO};
if (!_hasLine) exitWith {
    ["No IV/IO at that site.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    call ACME_fnc_skBuildHotspots;
};

playSound "ACME_SyringeDraw";
[ACE_player, _patient, _bodyPart, ["flushLine", uiNamespace getVariable ["ACME_SK_SiteIdx", -2]]] call ACME_fnc_salineFlush;

// keep the body map open. if the medic still has flushes, leave flush mode armed for another site, and otherwise
// return to normal syringe-selection mode.
if (([ACE_player, _flushClass] call ace_common_fnc_getCountOfItem) < 1) then {
    uiNamespace setVariable ["ACME_SK_SelFlush", ""];
};
call ACME_fnc_skBuildHotspots;
