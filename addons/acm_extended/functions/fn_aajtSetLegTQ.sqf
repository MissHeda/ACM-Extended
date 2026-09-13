/*
 * Legacy entry name retained for save/script compatibility. This no longer manufactures an ACE tourniquet.
 * It refreshes native wound loss for any proximally occluded limb and releases held medication only after both
 * the AAJT-S and a conventional ACE tourniquet are off that limb.
 */
params ["_patient", "_limb", ["_on", true], ["_epoch", -1]];
if (isNull _patient) exitWith {};
if (_epoch < 0) then {_epoch = [_patient] call ACME_fnc_clinicalEpoch;};
if (!local _patient) exitWith {[_patient, "aajtFlow", [_patient, _limb, _on, _epoch]] call ACME_fnc_ownerDispatch;};
if (_epoch != ([_patient] call ACME_fnc_clinicalEpoch)) exitWith {};
private _i = ["head","body","leftarm","rightarm","leftleg","rightleg"] find toLowerANSI _limb;
if !(_i in [2,3,4,5]) exitWith {};
[_patient] call ace_medical_status_fnc_updateWoundBloodLoss;
if (_on || {[_patient, _i] call ACME_fnc_aajtOccludes} || {((_patient getVariable ["ace_medical_tourniquets", [0,0,0,0,0,0]]) select _i) > 0}) exitWith {};
private _queued = _patient getVariable ["ace_medical_occludedMedications", []];
private _release = _queued select {(_x param [0, -1]) == _i};
if (_release isEqualTo []) exitWith {};
[_patient, [["occludedMedications", _queued select {(_x param [0, -1]) != _i}, true]]] call ACM_core_fnc_setAceMedicalState;
{_x params ["", "_medication", "_dose", "_iv", ["_delivery", []]]; [_patient, _limb, _medication, _dose, _iv, false, _delivery] call ace_medical_treatment_fnc_medicationLocal;} forEach _release;
