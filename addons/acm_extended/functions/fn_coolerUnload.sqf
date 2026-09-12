// move the selected unit out of the cooler back into inventory. it starts warming, handled by the normal loose
// cold-chain once it is a real item again.
private _dlg = uiNamespace getVariable ["ACME_CLR_DLG", displayNull];
if (isNull _dlg) exitWith {};
private _class = uiNamespace getVariable ["ACME_CLR_Class", ""];
if (_class == "") exitWith {};

private _lin = _dlg displayCtrl 87410;
private _sel = lbCurSel _lin;
if (_sel < 0) exitWith {};
private _idx = parseNumber (_lin lbData _sel);

private _store = ACE_player getVariable ["ACME_coolerStore", createHashMap];
private _contents = _store getOrDefault [_class, []];
if (_idx < 0 || _idx >= count _contents) exitWith {};
private _bc = (_contents select _idx) select 0;

// always pull the unit out and put it in the inventory of the player, never on the floor. if it fits normally, use
// additem for a clean slot placement. if the inventory is full, arma's additem refuses, so we force the bag into
// the cargo of a worn container, preferring the backpack, then the vest, then the uniform, with
// addItemCargoGlobal, which overloads that container past its maximumload rather than dropping the bag. it is a
// feet-drop only if the unit wears no container at all, such as being fully stripped. so the bag is never
// lost.
_contents deleteAt _idx;
_store set [_class, _contents];
[ACE_player, "store", _store, false] call ACME_fnc_coolerStateCommit;
// suppress auto-store for a short window, so the unit we just pulled out is not immediately grabbed back in by the
// loadout-triggered auto-store. the medic clearly wants this unit in hand right now.
missionNamespace setVariable ["ACME_coolerAutoStoreSuppressUntil", diag_tickTime + 3];
// the 3 s window only covers the immediate re-fire. to make a manual unload stay out, because the medic opens the
// transfusion menu and spikes it many seconds later, which re-fires the loadout event, also track how many units
// have been deliberately pulled out. auto-store leaves this many loose bags alone. the count self-corrects down
// in fn_coolerautostore as those bags are spiked, used, so the loose count drops, or manually re-loaded.
missionNamespace setVariable ["ACME_coolerManualOut", (missionNamespace getVariable ["ACME_coolerManualOut", 0]) + 1];
if (ACE_player canAdd _bc) then {
    ACE_player addItem _bc;
} else {
    // the inventory is full, so force it into the cargo of a worn container, overloading it. pick the first real
    // container.
    private _cont = objNull;
    {
        if (!isNull _x) exitWith { _cont = _x; };
    } forEach [backpackContainer ACE_player, vestContainer ACE_player, uniformContainer ACE_player];
    if (!isNull _cont) then {
        _cont addItemCargoGlobal [_bc, 1];
    } else {
        private _wh = createVehicle ["GroundWeaponHolder", getPosATL ACE_player, [], 0.5, "CAN_COLLIDE"];
        _wh addItemCargoGlobal [_bc, 1];
        ["No container. Unit dropped.", 2] call ace_common_fnc_displayTextStructured;
    };
};
call ACME_fnc_coolerRefresh;
