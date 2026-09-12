params [["_position", 0.5], ["_silent", false]];

_position = (_position max 0) min 1;

// keep the dialog visuals coherent no matter what happens with the data side.
uiNamespace setVariable ["ACME_RollerClamp_Position", _position];
[_position] call ACME_fnc_playClampSfx;

private _result = call ACME_fnc_getSelectedInfusionEntryIndexes;
if (_result isEqualTo []) exitWith {
    if (!_silent) then {["Select an active medication saline bag first.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;};
    call ACME_fnc_updateClampDialog;
    false
};

_result params ["_patient", "_indexes"];
if (_indexes isEqualTo []) exitWith {
    if (!_silent) then {["Selected saline bag has no medication additive.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;};
    call ACME_fnc_updateClampDialog;
    false
};

private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _ids = _indexes apply {(_entries select _x) select 0};
[_patient, "infusionClamp", [_patient, _ids, [_patient] call ACME_fnc_clinicalEpoch, _position, -1]] call ACME_fnc_ownerDispatch;

call ACME_fnc_updateTransfusionControls;
call ACME_fnc_updateClampDialog;
true
