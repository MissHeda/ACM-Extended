/* B13: append immutable IDs only to binding-relevant records. Native first 15 fields unchanged.
   A full heal clears bindings, not the monotonic sequence; migration cannot reuse an old ID. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
private _records = _patient getVariable ["ace_medical_medications", []];
private _serial = _patient getVariable ["ACME_medicationSerial", 0];
private _changed = false;
{
    if ((_x param [0, ""]) in ["Rocuronium", "Rocuronium_IV", "Sugammadex_IV"] && {(_x param [15, ""]) == ""}) then {
        _serial = _serial + 1;
        _x set [15, format ["B13:%1:%2:%3", netId _patient, clientOwner, _serial]];
        _changed = true;
    };
} forEach _records;
if (_changed) then {
    _patient setVariable ["ACME_medicationSerial", _serial, true];
    [_patient, [["medications", _records, true]]] call ACM_core_fnc_setAceMedicalState;
};
