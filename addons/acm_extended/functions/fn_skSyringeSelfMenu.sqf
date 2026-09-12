params ["_target","_player","_params"];
if (isNil "ace_interact_menu_fnc_createAction") exitWith {[]};
private _out = [];
private _store = [_player] call ACME_fnc_skStoreEnsureIds;
{
    private _idx = _forEachIndex;
    private _e = _x;
    private _id = _e param [11,"",[""]];
    if (_id == "") then {continue};
    private _remembered = [_store,_idx] call ACME_fnc_skSyringeRemembered;
    private _label = if (_remembered) then {[_e] call ACME_fnc_skSyringeSummary} else {"???"};
    private _tagName = _e param [8,"",[""]];
    if (_tagName != "") then {_label = format ["%1 - %2",_tagName,_label];};
    private _size = _e param [1,10,[0]];
    if !(_size in [1,3,5,10]) then {_size = 10;};
    private _icon = format ["\x\ACM\addons\circulation\ui\syringe_%1_ca.paa",_size];
    private _a = [
        format ["ACME_StoredSyringe_%1",_idx],
        _label,
        _icon,
        {(_this select 2) params ["_id"]; [_id] call ACME_fnc_skOpenStoredSyringe;},
        {true},
        {},
        [_id]
    ] call ace_interact_menu_fnc_createAction;
    _out pushBack [_a,[],_target];
} forEach _store;
_out
