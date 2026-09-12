// take a golden hour CSWB-4u out of a nearby vehicle, supply box or ground holder and force it into the worn
// container of the medic, overloading past the normal weight limit.
// the 4u is deliberately too heavy and bulky to enter a personal loadout the normal way, being vehicle cargo only,
// and this is the deliberate carry-it-anyway path.
// the cold-chain contents of the 4u are virtual and managed by the contents tick once it is actually carried: a
// brand-new 4u fills with its rated units when first held, and one previously filled keeps whatever blood it had.
// call ACME_fnc_take4U, as a self-action statement.
private _p = ACE_player;
if (isNull _p) exitWith {};
private _cls = "ACME_BloodCooler_CSWB4U";

// the nearest source within reach holding a 4u in its item cargo.
private _src = objNull;
{
    if (_x != _p && {_cls in (itemCargo _x)}) exitWith { _src = _x; };
} forEach (nearestObjects [_p, ["AllVehicles", "ReammoBox_F", "WeaponHolderSimulated", "GroundWeaponHolder"], 6]);

if (isNull _src) exitWith {
    ["No nearby vehicle or container holds a Golden Hour 4U.", 2] call ace_common_fnc_displayTextStructured;
};

// pull one 4u out of the item cargo of the source. clearItemCargoGlobal only clears the item category, so the
// weapons, magazines and backpacks of the source are untouched, and we re-add every item except the one 4u we are
// taking.
private _cargo = itemCargo _src;
private _i = _cargo find _cls;
if (_i >= 0) then { _cargo deleteAt _i; };
clearItemCargoGlobal _src;
{ _src addItemCargoGlobal [_x, 1]; } forEach _cargo;

// force it into a worn container, preferring the backpack, then the vest, then the uniform, overloading past
// maximumload.
private _cont = objNull;
{ if (!isNull _x) exitWith { _cont = _x; }; } forEach [backpackContainer _p, vestContainer _p, uniformContainer _p];
if (!isNull _cont) then {
    _cont addItemCargoGlobal [_cls, 1];
    ["Golden Hour 4U loaded. Inventory overloaded.", 2] call ace_common_fnc_displayTextStructured;
} else {
    // there is no worn container at all, so put it back so it is never lost.
    _src addItemCargoGlobal [_cls, 1];
    ["No worn container to hold the 4U.", 2] call ace_common_fnc_displayTextStructured;
};
