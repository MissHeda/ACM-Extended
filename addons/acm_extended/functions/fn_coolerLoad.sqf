// move the selected loose blood bag from inventory into the cooler, where it goes cold. it removes the real item
// and adds a virtual entry to the cooler store of the player. it is capacity-checked.
private _dlg = uiNamespace getVariable ["ACME_CLR_DLG", displayNull];
if (isNull _dlg) exitWith {};
private _class = uiNamespace getVariable ["ACME_CLR_Class", ""];
if (_class == "") exitWith {};

private _lout = _dlg displayCtrl 87411;
private _sel  = lbCurSel _lout;
if (_sel < 0) exitWith {};
private _bag = _lout lbData _sel;
if (_bag == "") exitWith {};

private _cap   = floor ((getNumber (configFile >> "CfgWeapons" >> _class >> "ACME_coolerCapacityMl")) / 500);
private _store = ACE_player getVariable ["ACME_coolerStore", createHashMap];
private _contents = _store getOrDefault [_class, []];

if (count _contents >= _cap) exitWith { ["The cooler is full.", 2] call ace_common_fnc_displayTextStructured; };
if !(_bag in ((uniformItems ACE_player) + (vestItems ACE_player) + (backpackItems ACE_player))) exitWith {
    call ACME_fnc_coolerRefresh;
};

ACE_player removeItem _bag;
_contents pushBack [_bag, 0];  // entering the cooler resets the warm clock (it's cold now)
_store set [_class, _contents];
[ACE_player, "store", _store, false] call ACME_fnc_coolerStateCommit;
call ACME_fnc_coolerRefresh;
