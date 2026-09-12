// ctrl+win on a minigame panel opens ACE's own interaction menu, filtered down to just the flashlight, exactly the
// way the map does it. there is no custom picker.
// how the filter works: ACE's self-interact hides every action that does not except "notOnMap". we extend notOnMap,
// in fn_postInit, to be false while the flashlight flag is up, so the menu collapses to our
// ACME_MinigameFlashlight entry, which is ACE's own compileflashlightmenu.
// ACE's keydown runs while {dialog} do {closedialog 0} and closes the minigame the instant ctrl+win is pressed.
// because the filter reads a flag, ACME_flashlightMenuActive, rather than the live display handle, it survives
// that close. the panel is rebuilt from its saved procedure state when ACE's menu closes, in fn_minigamereopen.
// the old diagnostic dump path was retired for the v1.1.0 release cleanup.
// call it as [_display] call ACME_fnc_installLightKey.
params ["_display"];
if (isNull _display) exitWith {};

// the shared forwarder: arm the flashlight flow, then hand the key to ACE's real keydown. _reopenCls is "" in
// display mode, because there is nothing to rebuild, and the dialog class of the minigame in dialog mode.
private _fnc_forward = {
    params ["_ctrl", "_reopenCls"];
    private _type = if (_ctrl) then {1} else {0};  // ctrl+win is the self-interaction, menu type 1, and win is the world, type 0.

    // diagnostic dump 1: the full pre-keydown state.
    [format ["forward: ctrl=%1 type=%2 reopenCls=%3", _ctrl, _type, _reopenCls], "PRE-FORWARD"] call ACME_fnc_flashlightDiag;

    if (isNil "ace_interact_menu_fnc_keyDown") exitWith {
        ["ace_interact_menu_fnc_keyDown IS NIL. ACE interact_menu not loaded", "ABORT"] call ACME_fnc_flashlightDiag;
        false
    };
    uiNamespace setVariable ["ACME_ace_menuType", _type];

    // keep the filter alive across the dialog close.
    missionNamespace setVariable ["ACME_flashlightMenuActive", true];
    missionNamespace setVariable ["ACME_flashlightMenuActiveAt", diag_tickTime];

    // arm the panel rebuild, in dialog mode. it is empty in display mode.
    uiNamespace setVariable ["ACME_minigame_reopen", _reopenCls];

    // force ACE's cursor-menu path, which is the map machine.
    if (isNil "ACME_ace_cursorSaved") then {
        ACME_ace_cursorSaved = [
            missionNamespace getVariable ["ace_interact_menu_alwaysUseCursorSelfInteraction", false],
            missionNamespace getVariable ["ace_interact_menu_alwaysUseCursorInteraction", false]
        ];
    };
    [true, true] call ACM_core_fnc_setCursorInteractionMode;

    // diagnostic dump 2: the flag is now set and we are about to call ACE.
    [format ["flag set (active=%1), cursor forced, calling ace keyDown type=%2",
        missionNamespace getVariable ["ACME_flashlightMenuActive", false], _type], "ABOUT-TO-CALL-ACE"] call ACME_fnc_flashlightDiag;

    [_type] call ace_interact_menu_fnc_keyDown;

    // diagnostic dump 3: immediately after ACE's keydown returned.
    [format ["ace keyDown returned | dialog=%1 cursorMenu91919=%2 openedType=%3 keyDownSelf=%4",
        dialog, !isNull (findDisplay 91919),
        missionNamespace getVariable ["ace_interact_menu_openedMenuType", "?"],
        missionNamespace getVariable ["ace_interact_menu_keyDownSelfAction", "?"]], "POST-ACE-KEYDOWN"] call ACME_fnc_flashlightDiag;
    true
};
uiNamespace setVariable ["ACME_lightKey_forward", _fnc_forward];

if (uiNamespace getVariable ["ACME_minigame_openedAsDisplay", false]) exitWith {
    // display mode. it should never run now and is kept for completeness. forward both halves.
    _display displayAddEventHandler ["KeyDown", {
    if (_this call ACME_fnc_minigameInput) exitWith {true};
        params ["", "_key", "", "_ctrl", "_alt"];
        if (_alt) exitWith {false};
        if (_key in [0xDB, 0xDC]) exitWith { [_ctrl, ""] call (uiNamespace getVariable ["ACME_lightKey_forward", {false}]); };
        false
    }];
    _display displayAddEventHandler ["KeyUp", {
    if ((_this + [true]) call ACME_fnc_minigameInput) exitWith {true};
        params ["", "_key"];
        if (isNil "ace_interact_menu_fnc_keyUp") exitWith {false};
        if (_key in [0xDB, 0xDC]) exitWith {
            private _type = uiNamespace getVariable ["ACME_ace_menuType", 1];
            [_type, false] call ace_interact_menu_fnc_keyUp;
            true
        };
        false
    }];
};

// dialog mode, which is what ships: forward ctrl+win to ACE. ACE closes this dialog and opens its filtered menu,
// and ACE's own cursormenu machinery plus CBA handle the release-to-commit, so we do not forward keyup.
_display displayAddEventHandler ["KeyDown", {
    if (_this call ACME_fnc_minigameInput) exitWith {true};
    params ["_disp", "_key", "", "_ctrl", "_alt"];
    // diagnostic: log every keydown that reaches this dialog, so we can prove keys are arriving at all.
    if ((_key in [0xDB, 0xDC]) && {_ctrl} && {!_alt}) exitWith {
        private _reopen = "";
        if (!isNull (uiNamespace getVariable ["ACME_IV_DLG", displayNull]))    then { _reopen = "ACME_IVMinigame_Dialog"; };
        if (!isNull (uiNamespace getVariable ["ACME_CS_DLG", displayNull]))    then { _reopen = "ACME_ChestSeal_Dialog"; };
        if (!isNull (uiNamespace getVariable ["ACME_Thora_DLG", displayNull])) then { _reopen = "ACME_Thoracostomy_Dialog"; };
        // the syringe kit rebuilds like the airway screen rather than the other three: its onload repopulates the
        // size and source lists and resets the barrel, so a bare rebuild would bin a part-drawn syringe. snapshot
        // the syringe itself and put it back after the rebuild, in fn_minigamereopen.
        if (!isNull (uiNamespace getVariable ["ACME_SK_DLG", displayNull])) then {
            _reopen = "ACME_SyringeKit_Dialog";
            uiNamespace setVariable ["ACME_SK_snap", [
                uiNamespace getVariable ["ACME_SK_Size", 10],
                uiNamespace getVariable ["ACME_SK_Vol", 0],
                uiNamespace getVariable ["ACME_SK_Source", ""],
                uiNamespace getVariable ["ACME_SK_Med", ""],
                uiNamespace getVariable ["ACME_SK_SalineBase", -1],
                uiNamespace getVariable ["ACME_SK_EpiMl", 0]
            ]];
        };
        // the airway screen was added to this system in a later build and never added to this list, so ACE closed it and
        // nothing ever asked for it back. that is why the flashlight worked and the minigame did not return.
        if (!isNull (uiNamespace getVariable ["ACME_laryngo_dlg", displayNull])) then {
            _reopen = "ACME_Laryngoscopy_Dialog";
            // snapshot the procedure. unlike the other three, the init of the airway screen resets itself to idle, so a rebuild
            // would hand the medic a fresh laryngoscope halfway through an intubation. the parts that are the procedure are
            // saved here and put back after the rebuild.
            uiNamespace setVariable ["ACME_laryngo_snap", [
                uiNamespace getVariable ["ACME_laryngo_state", "idle"],
                uiNamespace getVariable ["ACME_laryngo_held", ""],
                uiNamespace getVariable ["ACME_laryngo_lift", 0],
                uiNamespace getVariable ["ACME_laryngo_reveal", 0],
                uiNamespace getVariable ["ACME_laryngo_bladePic", 0],
                uiNamespace getVariable ["ACME_laryngo_bladeLocked", false],
                uiNamespace getVariable ["ACME_laryngo_airwayOpen", false],
                uiNamespace getVariable ["ACME_laryngo_tubeInHand", false],
                uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0],
                uiNamespace getVariable ["ACME_laryngo_tubeAnchored", false],
                uiNamespace getVariable ["ACME_laryngo_tubeAnchorRel", []],
                uiNamespace getVariable ["ACME_laryngo_tubeAimLock", ""],
                uiNamespace getVariable ["ACME_laryngo_sucPinned", false],
                uiNamespace getVariable ["ACME_laryngo_sucPinRel", []],
                // Exact committed passage survives a display rebuild before cuff
                // inflation. Depth alone also describes unsuccessful attempts.
                uiNamespace getVariable ["ACME_laryngo_tubePassed", false]
            ]];
        };
        [true, _reopen] call (uiNamespace getVariable ["ACME_lightKey_forward", {false}]);
    };
    false
}];
