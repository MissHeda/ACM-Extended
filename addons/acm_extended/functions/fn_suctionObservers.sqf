/* B13: retain other providers' live suction work, including parked catheters. */
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (isNull _dlg || {isNull _patient}) exitWith {};
private _medic = uiNamespace getVariable ["ACME_laryngo_medic", objNull];
private _controls = _dlg getVariable ["ACME_suctionObservers", createHashMap];
private _live = (_patient getVariable ["ACME_suctionSessions", []]) select {(_x select 1) != _medic && {(_x select 2) > CBA_missionTime}};
private _ids = _live apply {_x select 0};
{if !(_x in _ids) then {ctrlDelete (_controls get _x); _controls deleteAt _x;};} forEach (keys _controls);
(uiNamespace getVariable ["ACME_laryngo_frame", [0,0,1,1]]) params ["_fx","_fy","_fw","_fh"];
(uiNamespace getVariable ["ACME_Laryngo_ShakeBase_off", [0,0]]) params ["_dx","_dy"];
{
    _x params ["_id","_provider","","_mode","","","_position","_type"];
    if (count _position >= 2) then {
        private _c = _controls getOrDefault [_id, controlNull];
        if (isNull _c) then {_c = _dlg ctrlCreate ["RscPictureKeepAspect", -1]; _controls set [_id, _c];};
        private _dev = [_type] call ACME_fnc_suctionDevice;
        (_dev getOrDefault ["tipUV", [0.5703,0.02539]]) params ["_u","_v"];
        private _w = _fw * (_dev getOrDefault ["scale", 0.55]);
        private _h = _fh * (_dev getOrDefault ["scale", 0.55]) * (_dev getOrDefault ["aspect", 2]);
        _c ctrlSetPosition [_fx + _dx + (_position select 0) * _fw - _u * _w, _fy + _dy + (_position select 1) * _fh - _v * _h, _w, _h];
        _c ctrlCommit 0;
        _c ctrlSetText (_dev getOrDefault ["tray", "\acm_extended\ui\laryngo\suction\yank_master.paa"]);
        _c ctrlSetTextColor [1,1,1,0.8];
        _c ctrlSetTooltip format ["%1: %2", [_provider, false, true] call ace_common_fnc_getName, if (_mode == "salad") then {"SALAD parked"} else {"suctioning"}];
    };
} forEach _live;
_dlg setVariable ["ACME_suctionObservers", _controls];
