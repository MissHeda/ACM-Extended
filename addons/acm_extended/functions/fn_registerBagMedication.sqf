params ["_context", "_medication", "_doseMg", ["_durationSeconds", -1], ["_dropSet", -1], ["_dropsPerMinute", -1], ["_clampPosition", -1], ["_receipt", []], ["_solutionMl", 0]];
private _patient = _context param [0, objNull];
if (isNull _patient || {_doseMg <= 0}) exitWith {""};
private _part = _context param [1, ""]; private _index = _context param [2, -1];
private _id = _context param [11, ""];
if (_id == "") then {_id = [_patient, _part, _index] call ACME_fnc_bagIdentity;};
ACME_infusionRequestSeq = (missionNamespace getVariable ["ACME_infusionRequestSeq", 0]) + 1;
private _uid = format ["dose:%1:%2:%3", clientOwner, CBA_missionTime, ACME_infusionRequestSeq];
private _args = [_context, _medication, _doseMg, _durationSeconds, _dropSet, _dropsPerMinute, _clampPosition, _uid, _id, [_patient] call ACME_fnc_clinicalEpoch, _receipt, _solutionMl];
if !(_receipt isEqualTo []) then {
    missionNamespace setVariable ["ACME_infusion_pendingInject", _uid];
    private _pending = missionNamespace getVariable ["ACME_infusionPending", createHashMap];
    _pending set [_uid, [_patient, _args, _receipt, CBA_missionTime, false]];
    missionNamespace setVariable ["ACME_infusionPending", _pending];
};
[_patient, "infusionRegister", _args] call ACME_fnc_ownerDispatch;
_uid
