// draw the other medics working this chest: their raking fingers, or the seal or NAR SPEAR in their hand, live, in
// everyone's minigame at once. it is called from the tick.
// the fingers are drawn as the same generated dots the local player sees, ACME_CS_Dot: four for the rake and one
// for the palpate feeler, at the exact points the client of the peer computed. their normalized coordinates are
// mapped onto our body rect, so this is correct across mismatched resolutions and aspect ratios.
// only peers who are on this same patient, on the same side we are looking at, and reporting recently are drawn, so
// a medic who flips to the back or closes the dialog fades out instead of leaving a hand stuck on the chest.
// call it as [_patient, _side, _bodyRect] call ACME_fnc_chestSealPresenceRender.
params ["_patient", "_side", "_bodyRect"];
disableSerialization;
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (isNull _display || {isNull _patient}) exitWith {};
_bodyRect params ["_bx", "_by", "_bw", "_bh"];
if (!(_bw > 0) || {!(_bh > 0)}) exitWith {};

private _all = missionNamespace getVariable ["ACME_CS_presence", createHashMap];
private _peers = _all getOrDefault [netId _patient, createHashMap];
private _meId = netId (uiNamespace getVariable ["ACME_CS_presenceViewer", player]);
private _now = diag_tickTime;
private _stale = missionNamespace getVariable ["ACME_CS_presenceStale", 0.5];
// Expire storage and any held peel visual.
private _burpExpired = false;
{
    private _entry = _peers get _x;
    if ((_now - (_entry param [4, -1])) > _stale) then {
        if (count (_entry param [5, []]) > 0) then { _burpExpired = true; };
        _peers deleteAt _x;
    };
} forEach (keys _peers);
if (count _peers == 0) then { _all deleteAt (netId _patient); };
if (_burpExpired) then { [] call ACME_fnc_chestSealRender; };

// the peer dots use our local dot size, so they read identically to the fingers of the player.
private _dotW = uiNamespace getVariable ["ACME_CS_DotW", 0.006];
private _dotH = uiNamespace getVariable ["ACME_CS_DotH", 0.011];

private _pool = uiNamespace getVariable ["ACME_CS_GhostPool", []];  // [ctrl, kind] entries, reused.
private _used = 0;

// fetch, or grow, the next pooled control of the required kind.
private _fnc_next = {
    params ["_kind"];
    while { count _pool <= _used } do { _pool pushBack [controlNull, ""]; };
    (_pool select _used) params ["_c", "_haveKind"];
    if (isNull _c || {_haveKind != _kind}) then {
        if (!isNull _c) then { ctrlDelete _c; };
        _c = _display ctrlCreate [_kind, -1];
        _c ctrlEnable false;
        _pool set [_used, [_c, _kind]];
    };
    _used = _used + 1;
    _c
};

{
    private _id = _x;
    private _e = _peers get _id;
    if (!isNil "_e" && {_id != _meId}) then {
        _e params ["_pName", "_pSide", "_pTool", "_pts", "_pT"];
        if ((_now - _pT) <= _stale && {_pSide == _side} && {!(_pts isEqualTo [])}) then {
            switch (_pTool) do {
                case "seal": {
                    private _c = ["ACME_CS_PlacedSeal"] call _fnc_next;
                    private _sw = uiNamespace getVariable ["ACME_CS_SealW", 0.03];
                    private _sh = uiNamespace getVariable ["ACME_CS_SealH", 0.05];
                    (_pts select 0) params ["_nx", "_ny"];
                    _c ctrlSetTextColor [0.55, 0.85, 1, 0.75];
                    _c ctrlSetPosition [_bx + (_bw * _nx) - (_sw/2), _by + (_bh * _ny) - (_sh/2), _sw, _sh];
                    _c ctrlCommit 0; _c ctrlShow true;
                };
                case "spear": {
                    private _c = ["ACME_CS_NCDSprite"] call _fnc_next;
                    (_pts select 0) params ["_nx", "_ny"];
                    _c ctrlSetTextColor [0.55, 0.85, 1, 0.75];
                    // Match the sender's authored side-specific needle and tip anchor.
                    private _left = _nx >= 0.5;
                    _c ctrlSetText (if (_left) then {"\acm_extended\ui\items\nar_spear_left_ca.paa"} else {"\acm_extended\ui\items\nar_spear_right_ca.paa"});
                    private _tipFx = if (_left) then {0.4502} else {0.5493};
                    _c ctrlSetPosition [_bx + (_bw * _nx) - (_bw * _tipFx), _by + (_bh * _ny) - (_bh * 0.4971), _bw, _bh];
                    _c ctrlCommit 0; _c ctrlShow true;
                };
                default {
                    // fingers: one dot per fingertip the peer actually has down. 4 is the rake and 1 is the palpate.
                    {
                        _x params ["_nx", "_ny"];
                        private _c = ["ACME_CS_Dot"] call _fnc_next;
                        _c ctrlSetTextColor [0.55, 0.85, 1, 0.80];  // cyan: clearly the hand of somebody else.
                        _c ctrlSetPosition [_bx + (_bw * _nx) - (_dotW/2), _by + (_bh * _ny) - (_dotH/2), _dotW, _dotH];
                        _c ctrlCommit 0; _c ctrlShow true;
                    } forEach _pts;
                };
            };
        };
    };
} forEach (keys _peers);

uiNamespace setVariable ["ACME_CS_GhostPool", _pool];
// hide anything we did not use this frame, because the peer left, went stale, flipped sides or changed tool.
for "_i" from _used to ((count _pool) - 1) do {
    (_pool select _i) params ["_c", ""];
    if (!isNull _c) then { _c ctrlShow false; };
};
