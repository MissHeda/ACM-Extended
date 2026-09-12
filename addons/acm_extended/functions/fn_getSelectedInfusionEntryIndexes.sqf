private _stored = uiNamespace getVariable ["ACME_RollerClamp_Context", []];
if (!isNull (findDisplay 86200) && {!(_stored isEqualTo [])}) exitWith {
    _stored params ["_patient", "_indexes", ["_ids", []], ["_epoch", -1]];
    if (isNull _patient) exitWith {[]};
    if (_epoch >= 0 && {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {[]};
    if (_ids isEqualTo []) exitWith {[_patient, _indexes]};
    private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
    private _live = [];
    {private _uid = _x; private _i = _entries findIf {(_x param [0, ""]) == _uid}; if (_i >= 0) then {_live pushBack _i;};} forEach _ids;
    private _bagIds = _live apply {(_entries select _x) param [23, ""]};
    _live = [];
    {if ((_x param [23, ""]) in _bagIds && {(_x param [23, ""]) != ""}) then {_live pushBack _forEachIndex;};} forEach _entries;
    [_patient, _live]
};
private _display = findDisplay 86000;
if (isNull _display) then {
    if !(_stored isEqualTo []) exitWith {_stored};
};

private _context = ["infusion"] call ACME_fnc_getSelectedActiveBagContext;
if (_context isEqualTo []) exitWith {[]};

_context params ["_patient", "_bodyPart", "_bagIndex", "_type", "_accessType", "_bagAccessSite", "_bagIV", "_bloodType", "_volume", "_freshBloodID", "_remainingVolume"];

private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _indexes = [];

{
    _x params ["_uid", "_eBodyPart", "_eBagIndex", "_eType", "_eAccessSite", "_eIV", "_eBloodType", "_eVolume", "_eFreshBloodID"];
    if (_eBodyPart == _bodyPart && {_eBagIndex == _bagIndex} && {_eType == _type} && {_eAccessSite == _bagAccessSite} && {_eIV == _bagIV} && {_eBloodType == _bloodType} && {_eVolume == _volume} && {_eFreshBloodID == _freshBloodID}) then {
        _indexes pushBack _forEachIndex;
    };
} forEach _entries;

private _result = [_patient, _indexes];
if !(_indexes isEqualTo []) then {
    uiNamespace setVariable ["ACME_RollerClamp_Context", [_patient, _indexes, _indexes apply {(_entries select _x) select 0}, [_patient] call ACME_fnc_clinicalEpoch]];
};
_result
