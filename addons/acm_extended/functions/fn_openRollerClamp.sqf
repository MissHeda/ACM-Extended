private _result = call ACME_fnc_getSelectedInfusionEntryIndexes;
if (_result isEqualTo []) exitWith {
    ["Select an active medication saline bag first.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

_result params ["_patient", "_indexes"];
if (_indexes isEqualTo []) exitWith {
    ["Selected saline bag has no medication additive.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// The selection resolver has stored stable medication IDs for this clamp session.
private _returnBodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
uiNamespace setVariable ["ACME_RollerClamp_Return", [ACE_player, _patient, _returnBodyPart]];
createDialog "ACME_RollerClamp_Dialog";
