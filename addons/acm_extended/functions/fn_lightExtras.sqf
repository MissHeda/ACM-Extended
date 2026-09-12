// the light-emitting things ACE's own flashlight menu does not list.
// call it as [] call ACME_fnc_lightExtras, which returns an array of ACE child actions, or [] if there are none.
// ACE's compileflashlightmenu lists the handheld torches in your inventory. it does not list the light that is
// already bolted to your rifle, and on a night casualty that is usually the brightest thing the medic is carrying.
// a weapon light is a light. so is a laser, and an ir illuminator, and anything else a mod ships with a beam
// color on it. asking a medic to dig a maglite out of a pouch while a lit rifle hangs on their chest is the game
// arguing with the player about what a light is.
// everything here is read from config rather than named, so a modded accessory works the moment it declares the
// same entries ACE reads. there is no list of classnames to keep up to date.
// the test is ACE_Flashlight_Colour, which is the entry ACE itself keys on. anything carrying it can be handed
// straight to ace_map_fnc_switchFlashlight, and fn_darknessshade already reads that item's own beam texture and
// size, so a laser draws its own pool and a weapon light draws its.
if (!hasInterface) exitWith { [] };
if (isNil "ace_interact_menu_fnc_createAction") exitWith { [] };

private _out = [];
private _seen = [];

// what ACE already offers. we must not offer it twice, because two entries that both call switchflashlight on the
// same class means the second click turns off what the first turned on, and it reads as the menu ignoring you.
{
    private _a = _x param [0, []];
    private _n = _a param [0, ""];
    if (_n isEqualType "" && {_n != ""}) then { _seen pushBackUnique _n; };
} forEach (call ace_map_fnc_compileFlashlightMenu);

// the accessories actually fitted right now, across every weapon slot. a light in a pouch is already ACE's
// business, and this is about the one that is mounted and ready.
private _fitted = [];
{
    { _fitted pushBackUnique _x; } forEach (_x select 1);
} forEach [
    [primaryWeapon ACE_player,   primaryWeaponItems ACE_player],
    [handgunWeapon ACE_player,   handgunItems ACE_player],
    [secondaryWeapon ACE_player, secondaryWeaponItems ACE_player]
];

{
    private _cls = _x;
    if (_cls != "" && {!(_cls in _seen)}) then {
        private _cfg = configFile >> "CfgWeapons" >> _cls;
        if (isClass _cfg) then {
            // the same entry ACE keys on. no color means it is not a light, so a foregrip and a bipod fall out here
            // without needing to be excluded by name.
            private _color = getText (_cfg >> "ACE_Flashlight_Colour");
            if (_color != "") then {
                _seen pushBackUnique _cls;
                private _name = getText (_cfg >> "displayName");
                if (_name isEqualTo "") then { _name = _cls; };
                private _pic = getText (_cfg >> "picture");
                private _act = [
                    format ["ACME_light_%1", _cls],
                    _name,
                    _pic,
                    compile format ["[""%1""] call ACME_fnc_lightSelect", _cls],
                    {true}
                ] call ace_interact_menu_fnc_createAction;
                _out pushBack [_act, [], []];
            };
        };
    };
} forEach _fitted;

_out
