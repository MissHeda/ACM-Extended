// ui-first: the displayed drop set always cycles on click. the value is written through to the bag entries whenever
// a bag context is resolvable.
private _dropSets = missionNamespace getVariable ["ACME_infusion_dropSets", [10, 15, 20, 60]];
private _dropSet = uiNamespace getVariable ["ACME_RollerClamp_DropSet", missionNamespace getVariable ["ACME_infusion_defaultDropSet", 20]];
private _idx = _dropSets find _dropSet;
if (_idx < 0) then {_idx = 0} else {_idx = (_idx + 1) mod (count _dropSets)};
private _newDropSet = _dropSets select _idx;

uiNamespace setVariable ["ACME_RollerClamp_DropSet", _newDropSet];
uiNamespace setVariable ["ACME_RollerClamp_Flash", [format ["Drop set: %1 gtt/mL", round _newDropSet], CBA_missionTime + 1.25]];

// instant label feedback, independent of the update loop.
private _clampDisplay = findDisplay 86200;
if (!isNull _clampDisplay) then {
    private _ctrlDrop = _clampDisplay displayCtrl 86207;
    if (!isNull _ctrlDrop) then {_ctrlDrop ctrlSetText (format ["Drop Set: %1", round _newDropSet]);};
};

private _result = call ACME_fnc_getSelectedInfusionEntryIndexes;
if !(_result isEqualTo []) then {
    _result params ["_patient", "_indexes"];
    if !(_indexes isEqualTo []) then {
        private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
        private _ids = _indexes apply {(_entries select _x) select 0};
        private _position = uiNamespace getVariable ["ACME_RollerClamp_Position", 0];
        [_patient, "infusionClamp", [_patient, _ids, [_patient] call ACME_fnc_clinicalEpoch, _position, _newDropSet]] call ACME_fnc_ownerDispatch;
    };
};

call ACME_fnc_updateTransfusionControls;
call ACME_fnc_updateClampDialog;
true
