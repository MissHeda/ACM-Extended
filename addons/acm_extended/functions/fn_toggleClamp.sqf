private _drops = -1;

private _result = call ACME_fnc_getSelectedInfusionEntryIndexes;
if !(_result isEqualTo []) then {
    _result params ["_patient", "_indexes"];
    if !(_indexes isEqualTo []) then {
        private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
        private _entryIndex = _indexes select 0;
        if (_entryIndex >= 0 && {_entryIndex < count _entries}) then {
            _drops = (_entries select _entryIndex) param [21, 60];
        };
    };
};

// fall back to the cached wheel position of the dialog when no bag is resolvable.
if (_drops < 0) then {
    private _position = uiNamespace getVariable ["ACME_RollerClamp_Position", 1];
    _drops = [_position] call ACME_fnc_clampPositionToDrops;
};

private _newPosition = if (_drops > 0) then {0} else {missionNamespace getVariable ["ACME_infusion_defaultClampPosition", 1]};
[_newPosition, false] call ACME_fnc_setClampPosition;
