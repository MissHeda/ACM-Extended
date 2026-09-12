/* NA3. The ninth bag field is an opaque identity; native fields 0..7 remain unchanged. */
params ["_patient", "_part", "_index"];
if (isNull _patient) exitWith {""};
private _map = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _bags = _map getOrDefault [_part, []];
if (_index < 0 || {_index >= count _bags}) exitWith {""};
private _bag = +(_bags select _index);
private _id = _bag param [8, "", [""]];
if (_id != "" || {!local _patient}) exitWith {_id};
private _seq = (_patient getVariable ["ACME_bagSequence", 0]) + 1;
_patient setVariable ["ACME_bagSequence", _seq, true];
_id = format ["%1:%2:%3:%4", netId _patient, [_patient] call ACME_fnc_clinicalEpoch, clientOwner, _seq];
if (count _bag < 8) then {_bag set [7, -1];};
_bag set [8, _id]; _bags set [_index, _bag]; _map set [_part, _bags];
[_patient, _map] call ACME_fnc_ivBagsCommit;
_id
