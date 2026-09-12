/*
 * Refresh the current medical menu after an explicit accessibility change.
 * fn_updateActions.sqf owns the controls and preserves this display's open groups.
 * No extra PFH or network update is installed here.
 */
disableSerialization;
private _display = uiNamespace getVariable ['ace_medical_gui_menuDisplay', displayNull];
if (isNull _display) exitWith {
    missionNamespace setVariable ['ACME_leftAlign_diag', [false, 'no_display', missionNamespace getVariable ['ACME_a11y_menuLeftAlign', false], 0, 0], false];
};
if (!isNil 'ace_medical_gui_fnc_updateActions') then { [_display] call ace_medical_gui_fnc_updateActions; };
