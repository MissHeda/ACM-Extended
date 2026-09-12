// taking the collar off.
// call it as [] call ACME_fnc_laryngoCollarRemove.
// the collar is the only thing in this screen that is genuinely reversible without cost, because it is a strap. it
// goes back into the tray as a usable item, because in the field you re-secure with the same one.
// this does not free the tube on its own. it frees it to be fought. the cuff is still up and still sitting in the
// trachea below the cords, and that is a separate thing to undo.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (isNull _dlg) exitWith {};
private _pat = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (isNull _pat) exitWith {};
if (!(_pat getVariable ["ACME_ETT_Secured", false])) exitWith {
    ["There is no collar on this tube.", 2.5] call ace_common_fnc_displayTextStructured;
};

[_pat, -1, -1, false, true, true, false] call ACME_fnc_ettAirwayStateCommit;

// the fastened art comes off, and the collar returns to the tray.
(_dlg displayCtrl 87910) ctrlShow false;
(_dlg displayCtrl 87909) ctrlSetTextColor [1,1,1,0];
uiNamespace setVariable ["ACME_laryngo_collarUsed", false];
uiNamespace setVariable ["ACME_laryngo_state", "cuff"];
// B52: removal returns the collar to the tray and explicitly hands tube adjustment back to the normal cuff/tube
// controls. An inflated cuff still resists/locks movement until the medic deflates it.
uiNamespace setVariable ["ACME_laryngo_held", ""];
uiNamespace setVariable ["ACME_laryngo_tubeInHand", false];
uiNamespace setVariable ["ACME_laryngo_tubeGrip", false];
uiNamespace setVariable ["ACME_laryngo_tubeVel", 0];

[] call ACME_fnc_laryngoRefreshSlots;

playSound "ACME_VentClick";
if (_pat getVariable ["ACME_ETT_CuffInflated", false]) then {
} else {
};
