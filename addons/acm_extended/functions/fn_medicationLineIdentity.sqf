/* Exact current access identity: [site (-1 IO), generation, native access type].
   -2 chooses ONE present access on the requested part, not all accesses. Read-only on clients. */
params ["_patient", "_part", ["_site", -2]];
if (isNull _patient) exitWith {[]};
_part = toLowerANSI _part;
if (_part == "ej") then {_part = "head";};
private _parts = ["head","body","leftarm","rightarm","leftleg","rightleg"];
private _pi = _parts find _part;
if (_pi < 0) exitWith {[]};
private _ivs = _patient getVariable ["ACM_circulation_IV_Placement", [[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]]];
private _row = _ivs param [_pi, [0,0,0]];
private _ios = _patient getVariable ["ACM_circulation_IO_Placement", [0,0,0,0,0,0]];
if (_site == -2) then {
    _site = _row findIf {_x > 0};
    if (_site < 0) then {_site = -1;};
};
private _type = if (_site == -1) then {_ios param [_pi,0]} else {_row param [_site,0]};
if (_type <= 0) exitWith {[]};
private _generations = _patient getVariable ["ACME_medicationLineGenerations", createHashMap];
[_site, _generations getOrDefault [format ["%1:%2",_part,_site],0], _type]
