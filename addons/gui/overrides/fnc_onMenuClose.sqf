#include "..\script_component.hpp"
/*
 * Author: joko // Jonas
 * Handles closing the Medical Menu. Called from onUnload event.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ace_medical_gui_fnc_onMenuClose
 *
 * Public: No
 */

if (ACEGVAR(interact_menu,menuBackground) == 1) then {[QACEGVAR(medical_gui,id), false] call ACEFUNC(common,blurScreen)};
if (ACEGVAR(interact_menu,menuBackground) == 2) then {(uiNamespace getVariable [QACEGVAR(interact_menu,menuBackground), displayNull]) closeDisplay 0};

// Snapshot ACE's reopen intent before clearing it.  A real treatment button closes this display to create its
// progress UI and sets pendingReopen; a manual ESC/H/RMB close does not.  Direct Pressure must survive the former
// but must always release on the latter so no provider can be left stuck in the held pose after leaving the menu.
private _pendingReopen = ACEGVAR(medical_gui,pendingReopen);
private _dpMedic = ACE_player;
private _dpWasActive = !isNull _dpMedic && {_dpMedic getVariable ["ACME_DP_Active", false]};

ACEGVAR(medical_gui,pendingReopen) = false;
ACEGVAR(medical_gui,menuPFH) call CBA_fnc_removePerFrameHandler;
ACEGVAR(medical_gui,menuPFH) = -1;

if (_dpWasActive && {!_pendingReopen}) then {
    // Defer one frame so a treatment that replaced the menu synchronously can expose its progress display first.
    [{
        params ["_m"];
        if (isNull _m || {!local _m} || {!(_m getVariable ["ACME_DP_Active", false])}) exitWith {};
        private _progress = uiNamespace getVariable ["ace_common_dlgProgress", displayNull];
        private _menu = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
        if (isNull _progress && {isNull _menu}) then {[false, _m, false] call ACME_fnc_directPressureStop;};
    }, [_dpMedic]] call CBA_fnc_execNextFrame;
};
