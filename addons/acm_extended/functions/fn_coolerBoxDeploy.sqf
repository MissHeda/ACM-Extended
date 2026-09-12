// set a carried blood cooler down as a real, openable container box. the blood of the cooler, which until now was
// virtual and tracked in ACME_coolerStore keyed by cooler class, becomes real ACM blood bags in the cargo of the
// box, so from here it travels with the box: drag it, drop it, stash it in a vehicle or hand it to a teammate,
// all natively. the box is openable like any container and carryable through ACE drag.
// call ACME_fnc_coolerBoxDeploy, as a self-action statement.
private _p = ACE_player;
if (isNull _p) exitWith {};

// map the carried cooler item to its box class.
private _map = [
    ["ACME_BloodCooler_CSWB1U", "ACME_BloodCoolerBox_CSWB1U"],
    ["ACME_BloodCooler_CSWB2U", "ACME_BloodCoolerBox_CSWB2U"],
    ["ACME_BloodCooler_CSWB4U", "ACME_BloodCoolerBox_CSWB4U"]
];
private _carried = items _p;
private _itemClass = "";
private _boxClass  = "";
{
    if ((_x select 0) in _carried) exitWith { _itemClass = _x select 0; _boxClass = _x select 1; };
} forEach _map;
if (_itemClass == "") exitWith { ["No blood cooler to set down.", 2] call ace_common_fnc_displayTextStructured; };

// the virtual contents of this cooler, the blood that was inside it. each entry is [bagclass, warmtime].
private _store    = _p getVariable ["ACME_coolerStore", createHashMap];
private _contents = _store getOrDefault [_itemClass, []];

// if this cooler has never been stocked yet, meaning there is no coolant clock because the contents tick has not
// pre-filled it, stock the box now with its rated units of the fill type, so a just-drawn cooler deploys full
// instead of empty.
private _coolant = _p getVariable ["ACME_coolerCoolant", createHashMap];
if ((_contents isEqualTo []) && {isNil { _coolant get _itemClass }}) then {
    private _cap  = floor ((getNumber (configFile >> "CfgWeapons" >> _itemClass >> "ACME_coolerCapacityMl")) / 500);
    private _fill = missionNamespace getVariable ["ACME_coolerFillType", "ON"];
    for "_i" from 1 to _cap do { _contents pushBack [format ["ACM_BloodBag_%1_500", _fill], 0]; };
};

// spawn the box just in front of the medic.
private _pos = _p getRelPos [1.1, 0];
private _box = createVehicle [_boxClass, _pos, [], 0, "CAN_COLLIDE"];
_box setDir (getDir _p);

// shrink it toward cooler size. setObjectScale is ignored while the PhysX simulation of an object is active, and
// ammo and weapon boxes are physics objects, which is why the box never shrank: the bare scale call, local or
// broadcast, no-ops on them.
// the fix is to let the box settle on the ground, then disable its simulation on every machine and scale it. it
// becomes static, which is fine for a deployed cooler, because ACE drag uses attachto rather than physics and the
// box inventory is logical, so opening and dragging still work. setObjectScale also scales the interaction lods,
// so the inventory, drag and pick up scale with it. it is tied to the box, so jip joiners get it and it drops on
// pick-up.
private _scale = missionNamespace getVariable ["ACME_coolerBoxScale", 0.65];
if (_scale != 1) then {
    [{
        params ["_box", "_scale"];
        if (isNull _box) exitWith {};
        _box enableSimulation false;
        _box setObjectScale _scale;
        [_box, _scale] remoteExec ["ACME_fnc_coolerBoxApplyScale", 0, _box];
    }, [_box, _scale], 0.5] call CBA_fnc_waitAndExecute;
};

// clear the placeholder ammo-box default cargo, then load the blood of the cooler as real bags.
clearWeaponCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearItemCargoGlobal _box;
clearBackpackCargoGlobal _box;
{
    private _bag = _x param [0, ""];
    if (_bag != "") then { _box addItemCargoGlobal [_bag, 1]; };
} forEach _contents;

// stamp the identity and the coolant clock on the box. we carry over the coolant start of the carried cooler, when
// it was first stocked, rather than resetting to now, so deploying does not refresh the cold chain. a
// never-stocked cooler, with no entry, gets time, meaning full coolant, which is correct for a just-drawn
// unit.
_box setVariable ["ACME_boxCoolerClass", _itemClass, true];
_box setVariable ["ACME_boxCoolantStart", (_coolant getOrDefault [_itemClass, time]), true];

// a best-effort red tint. the config sets the "camo" selection red, and this also paints selections 0 to 2 by
// index, in case the recolorable selection of the model is not named "camo". it is a no-op on models with no
// hidden selections.
{ _box setObjectTextureGlobal [_x, "#(argb,8,8,3)color(0.62,0.10,0.10,1.0,co)"]; } forEach [0, 1, 2];

// guarantee drag and carry even if ACE's config init did not tag this class.
[_box, true, true, true] call ACM_core_fnc_setDraggingCapability;

// remove the carried item form and its now-emptied virtual store entry. the blood lives in the box now.
_p removeItem _itemClass;
_store deleteAt _itemClass;
[_p, "store", _store, false] call ACME_fnc_coolerStateCommit;

playSound "ACE_Sound_Click";
[format ["%1 set down. Blood is inside the box.", getText (configFile >> "CfgWeapons" >> _itemClass >> "displayName")], 2] call ace_common_fnc_displayTextStructured;
