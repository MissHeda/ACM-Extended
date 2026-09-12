/* NA4: only the target site may be corrected, synchronously on its owner.
   The legacy _before row is accepted for API compatibility but NEVER restored.
   Calls without the explicit episode are read-only diagnostics. */
params [["_patient",objNull], ["_bodyPart",""], ["_accessSite",-1], ["_type",0], ["_before",[]], ["_epoch",-1]];
if (isNull _patient || {!local _patient} || {_accessSite < 0} || {_accessSite > 2}) exitWith {false};
private _part = ["head","body","leftarm","rightarm","leftleg","rightleg"] find toLower _bodyPart;
if (_part < 0) exitWith {false};
private _state = _patient getVariable ["ACM_circulation_IV_Placement", []];
if (count _state <= _part) exitWith {false};
private _row = +(_state select _part);
if (count _row <= _accessSite) exitWith {false};
if ((_row select _accessSite) == _type) exitWith {true};
if (_epoch < 0 || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {
     false
};
_row set [_accessSite, _type];
private _next = +_state;
_next set [_part, _row];
[_patient, [["ivPlacement", _next]], true] call ACM_circulation_fnc_setRuntimeState;
true
