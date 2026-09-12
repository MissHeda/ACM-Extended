params ["_patient", "_ids", "_epoch", "_position", "_dropSet"];
if (!local _patient) exitWith {[_patient, "infusionClamp", _this] call ACME_fnc_ownerDispatch;};
if (_epoch != ([_patient] call ACME_fnc_clinicalEpoch) || {!alive _patient}) exitWith {};
if (!(_position isEqualType 0) || {!finite _position} || {_position < 0} || {_position > 1}) exitWith {};
private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _bags = [];
{if ((_x select 0) in _ids) then {_bags pushBackUnique (_x param [23, ""]);};} forEach _entries;
{
    if ((_x param [23, ""]) in _bags && {(_x param [23, ""]) != ""}) then {
        if (_dropSet > 0 && {_dropSet in (missionNamespace getVariable ["ACME_infusion_dropSets", [10,15,20,60]])}) then {_x set [20, _dropSet];};
        _x set [22, _position]; _x set [21, [_position] call ACME_fnc_clampPositionToDrops];
    };
} forEach _entries;
[_patient, _entries] call ACME_fnc_infusionMedicationStateCommit;
