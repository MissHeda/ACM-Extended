// pick a deployed cooler box back up into its carried item form, which is the reverse of fn_coolerboxdeploy. the
// real blood bags of the box move back into the virtual cooler store of the medic, keyed by the cooler class
// stamped on the box, the cooler item is returned to the medic, and the box is deleted.
// it is triggered from the "Pick Up Cooler" ACE interaction of the box, with the box as _target.
// call it as [_box] call ACME_fnc_coolerBoxPackUp.
params ["_box"];
if (isNull _box) exitWith {};
private _p = ACE_player;
if (isNull _p) exitWith {};

// which cooler item does this box correspond to? prefer the stamp and fall back to the box class for
// editor-placed ones.
private _itemClass = _box getVariable ["ACME_boxCoolerClass", ""];
if (_itemClass == "") then {
    _itemClass = switch (typeOf _box) do {
        case "ACME_BloodCoolerBox_CSWB1U": { "ACME_BloodCooler_CSWB1U" };
        case "ACME_BloodCoolerBox_CSWB2U": { "ACME_BloodCooler_CSWB2U" };
        case "ACME_BloodCoolerBox_CSWB4U": { "ACME_BloodCooler_CSWB4U" };
        default { "" };
    };
};
if (_itemClass == "") exitWith {};

// move the blood bags of the box back into the virtual store of the player, under this cooler class.
private _store    = _p getVariable ["ACME_coolerStore", createHashMap];
private _contents = _store getOrDefault [_itemClass, []];
{
    if ((_x find "ACM_BloodBag_") == 0) then { _contents pushBack [_x, 0]; };
} forEach (itemCargo _box);
_store set [_itemClass, _contents];
[_p, "store", _store, true] call ACME_fnc_coolerStateCommit;

// carry the coolant clock of the box back onto the cooler item, so the cold chain continues seamlessly. there is no
// refresh and no instant re-pre-fill, because the contents tick sees a clock already set and ages from here
// instead of re-stocking.
private _coolant = _p getVariable ["ACME_coolerCoolant", createHashMap];
_coolant set [_itemClass, (_box getVariable ["ACME_boxCoolantStart", time])];
[_p, "coolant", _coolant, false] call ACME_fnc_coolerStateCommit;

// return the carried item and remove the box.
_p addItem _itemClass;
deleteVehicle _box;

playSound "ACE_Sound_Click";
[format ["%1 picked up.", getText (configFile >> "CfgWeapons" >> _itemClass >> "displayName")], 2] call ace_common_fnc_displayTextStructured;
