// One cooldown per casualty, shared by traumatic and surgical seals and every provider.
// The clinical epoch makes a restored/spawned patient independent of a previous episode.
params ["_patient",["_commit",false]];
if (isNull _patient) exitWith {false};
private _epoch = [_patient] call ACME_fnc_clinicalEpoch;
private _last = _patient getVariable ["ACME_CS_burpCooldown",[-1,-1e6]];
if ((_last param [0,-1]) isEqualTo _epoch && {CBA_missionTime < (_last param [1,0])}) exitWith {false};
if (_commit && {local _patient}) then {
    private _seconds = missionNamespace getVariable ["ACME_chestSealBurpCooldown",10];
    if !(_seconds isEqualType 0 && {finite _seconds}) then {_seconds = 10;};
    _patient setVariable ["ACME_CS_burpCooldown",[_epoch,CBA_missionTime + (_seconds max 1)],true];
};
true
