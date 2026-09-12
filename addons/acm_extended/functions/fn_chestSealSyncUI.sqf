// Snapshot application never writes patient state. Preserve local prediction and burp identity.
params ["_patient", "_snapshot", ["_force", false]];
if (!hasInterface || {isNull _patient} || {count _snapshot < 5}) exitWith {};
if ((uiNamespace getVariable ["ACME_CS_Patient", objNull]) != _patient || {isNull (uiNamespace getVariable ["ACME_CS_DLG", displayNull])}) exitWith {};
disableSerialization;
_snapshot params ["_epoch", "_ver", "_data", "_wasted", "_ncd"];
private _previous = uiNamespace getVariable ["ACME_CS_netSnapshot", []];
// Revisions remain monotonic across a reset. An old-epoch event must not restore old wounds.
if (count _previous >= 5 && {_ver < (_previous select 1) || {!_force && {_ver == (_previous select 1)} && {_epoch == (_previous select 0)}}}) exitWith {};
private _holes = _data apply {(_x select [0, 6]) + [controlNull, controlNull, _x param [8, ""]]};
// Acknowledgement may arrive after a snapshot. Preserve unacknowledged local gestures,
// but NEVER carry them into a new reset epoch or publish them as a full patient record.
{
    private _req = (ACME_CS_pending get _x) select 0;
    if ((_req select 0) == _patient && {(_req select 4) == _epoch}) then {
        private _op = _req select 6;
        private _payload = _req select 7;
        if (_op in ["seal", "peel"]) then {
            private _i = _holes findIf {([_x] call ACME_fnc_chestSealKey) isEqualTo _payload};
            if (_i >= 0) then { (_holes select _i) set [4, _op == "seal"]; };
        };
        if (_op == "reveal") then {
            {
                private _key = _x;
                private _i = _holes findIf {([_x] call ACME_fnc_chestSealKey) isEqualTo _key};
                if (_i >= 0) then { (_holes select _i) set [3, true]; };
            } forEach _payload;
        };
        if (_op == "ncd") then {
            private _side = _payload param [0, ""];
            if (_side in ["left", "right"]) then { _ncd pushBackUnique _side; };
        };
    };
} forEach (keys ACME_CS_pending);
private _old = uiNamespace getVariable ["ACME_CS_Holes", []];
private _burp = uiNamespace getVariable ["ACME_CS_BurpIdx", -1];
private _burpKey = if (_burp >= 0 && {_burp < count _old}) then {[_old select _burp] call ACME_fnc_chestSealKey} else {[]};
{
    if (_x isEqualType [] && {count _x >= 8}) then {
        { if (!isNull _x) then { ctrlDelete _x; }; } forEach [_x select 6, _x select 7];
    };
} forEach _old;
private _newBurp = _holes findIf {([_x] call ACME_fnc_chestSealKey) isEqualTo _burpKey && {_x select 4}};
uiNamespace setVariable ["ACME_CS_BurpIdx", _newBurp];
if (_newBurp < 0) then { uiNamespace setVariable ["ACME_CS_BurpFrame", 0]; uiNamespace setVariable ["ACME_CS_BurpFired", false]; uiNamespace setVariable ["ACME_CS_BurpDir", 0]; };
uiNamespace setVariable ["ACME_CS_Holes", _holes];
uiNamespace setVariable ["ACME_CS_netSnapshot", [_epoch, _ver, _data apply {+_x}, _wasted apply {+_x}, +_ncd]];
uiNamespace setVariable ["ACME_CS_holeVerSeen", _ver];
[] call ACME_fnc_chestSealRender;
