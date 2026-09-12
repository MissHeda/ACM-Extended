params ["_itemClass", ["_actionClass", ""]];

private _entries = ACE_player getVariable ["ACME_infusion_PreparedBags", []];
private _result = -1;

{
    _x params ["_uid", "_pItemClass", "_pActionClass"];
    if (_pItemClass == _itemClass && {(_pActionClass == _actionClass) || {_actionClass == ""}}) exitWith {
        _result = _forEachIndex;
    };
} forEach _entries;

_result
