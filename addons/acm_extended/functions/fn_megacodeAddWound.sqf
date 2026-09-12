// apply a wound of the selected type to the currently-selected body region on the megacode dummy, using the real
// damage path of ACE, so the wound hooks of the mod, meaning the TBI, the junctional spawn and fire too, all fire.
// "clear" wipes all damage and wounds and restores the baseline blood. the damage is executed where the unit is
// local.
// _this is [_type].
params ["_type"];
private _d = uiNamespace getVariable ["ACME_MC_target", objNull];
if (isNull _d) exitWith {};
private _part = uiNamespace getVariable ["ACME_MC_woundPart", "Body"];

if (toLower _type == "clear") exitWith {
    [_d] remoteExec ["ACME_fnc_megacodeClearWounds", _d];
    ["Megacode: all wounds cleared.", 2] call ace_common_fnc_displayTextStructured;
    [["Cleared all wounds", "#9be08c"]] call ACME_fnc_megacodeLog;
};

// junctional hemorrhage spawns, where the axilla is the arms and the inguinal is the legs, capped at 2 per region in
// the spawner.
if (toLower _type in ["axilla", "inguinal"]) exitWith {
    [toLower _type] call ACME_fnc_megacodeSpawnJunctional;
};

// the type maps to [acedamagetype, amount].
private _map = createHashMapFromArray [
    ["laceration", ["stab", 0.22]],
    ["gunshot",    ["bullet", 0.40]],
    ["avulsion",   ["grenade", 0.45]],
    ["amputation", ["explosive", 0.92]],
    ["burn",       ["burn", 0.30]],
    ["crush",      ["vehiclecrash", 0.42]],
    ["velocity",   ["grenade", 0.45]]
];
private _e = _map getOrDefault [toLower _type, ["stab", 0.25]];
_e params ["_dmgType", "_amt"];

[_d, _amt, _part, _dmgType, objNull, objNull] remoteExec ["ace_medical_fnc_addDamageToUnit", _d];
[format ["Megacode: %1 -> %2.", _type, _part], 2] call ace_common_fnc_displayTextStructured;
[[format ["Wound: %1 -> %2", _type, _part], "#ff8a8a"]] call ACME_fnc_megacodeLog;
