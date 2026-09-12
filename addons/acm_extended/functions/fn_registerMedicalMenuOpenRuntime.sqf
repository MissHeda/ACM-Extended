// A targeted request lets a medic refresh premixed infusion state even when another client or the server owns
// the patient. The receiver writes only while the patient is local. The regular PFH catches an ownership change.
["ACME_syncPremixedBagsLocal", {
    params [["_patient", objNull, [objNull]]];
    if (!isNull _patient && {local _patient}) then {[_patient] call ACME_fnc_syncPremixedBags;};
}] call CBA_fnc_addEventHandler;

// the medical menu opened.
["ace_medicalMenuOpened", {
    params ["_medic", "_target", "_display"];

    // Register a premixed bag at once when the patient menu opens. Pass the target explicitly. A bare call here
    // inherits this event's _this array and previously treated the medic as the optional patient argument.
    [_target] call ACME_fnc_syncPremixedBags;

    // B57: another person's menu only stows the weapon and transitions into the normal unarmed crouch. No
    // medic-over-patient animation is held, so the player's head/camera remains free and there is no root drift.
    if (_medic isEqualTo ACE_player) then {
        [_medic, _target, _display] call ACME_fnc_menuPoseStart;
        if (!isNull _display) then {
            _display displayAddEventHandler ["Unload", {[ACE_player, false] call ACME_fnc_menuPoseStop;}];
        };
    };

    // the hardcore site relabel used to start a 0-delay PFH here that repainted ACE's buttons and injury list
    // after ACE had drawn them. it is gone. the buttons are now relabelled at the single ctrlSetText in
    // overrides/fn_updateActions.sqf, and the injury list on the ace_medical_gui_updateInjuryListPart event
    // below, both of which run inside ACE's own build rather than chasing it.
    // this also fixes a real defect: the PFH only started when hardcore was ALREADY on at the moment the menu
    // opened, so toggling the setting with the menu up appeared to do nothing.
}] call CBA_fnc_addEventHandler;
