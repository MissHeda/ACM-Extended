// how open is this vehicle to the airstream? it returns 0.0, sealed, through to 1.0, wide open.
// it is not a boolean, because it is not a boolean: doors shut, one door slid back, a ramp down and a doorless
// airframe are four different amounts of air moving over a casualty.
// the problem is that there is no generic way to ask arma whether the door is open. door animations are named
// differently by every author, as door_l, door_1_source, cargoramp_open or ramp_bottom, and are read by three
// different commands depending on how they were authored.
// ACE itself does not solve this generically: its rhs compat switches on the vehicle class and calls
// animationphase for a ch-53e, animationSourcePhase for a ch-47f, and doorphase for everything else. if ACE needs
// a per-class table, a hardcoded table here would break on the first mod nobody thought of.
// so we do not guess the names, we ask the config. enumerate the AnimationSources of the vehicle class, keep the
// ones that look like doors, ramps or hatches, and read each with all three commands, taking whichever answers.
// unknown modded aircraft therefore work with no compat entry, which is the whole point.
// call it as [_veh] call ACME_fnc_vehicleOpenness, which returns a number from 0 to 1.
params ["_veh"];
if (isNull _veh) exitWith {0};

// mission makers and mod compat can pin it directly, and that always wins.
private _forced = _veh getVariable ["ACME_vehicleOpen", nil];
if (!isNil "_forced" && {_forced isEqualType 0}) exitWith {(_forced max 0) min 1};

// cache per class: the door-source list never changes for a class, and this is a config walk.
private _type = typeOf _veh;
private _cache = missionNamespace getVariable ["ACME_vehOpenCache", createHashMap];
private _srcs = _cache getOrDefault [_type, nil];

if (isNil "_srcs") then {
    _srcs = [];
    private _cfg = configFile >> "CfgVehicles" >> _type >> "AnimationSources";
    {
        private _n = configName _x;
        private _l = toLower _n;
        // anything that reads like a way in or out. it is deliberately broad, because a false positive on an unknown mod
        // costs a little accuracy, while a false negative silently reports sealed and the casualty never gets cold.
        if (["door" , _l] call BIS_fnc_inString
            || {["ramp", _l] call BIS_fnc_inString}
            || {["hatch", _l] call BIS_fnc_inString}
            || {["cargo_open", _l] call BIS_fnc_inString}) then {
            _srcs pushBack _n;
        };
    } forEach (configProperties [_cfg, "isClass _x", true]);
    _cache set [_type, _srcs];
    missionNamespace setVariable ["ACME_vehOpenCache", _cache];
};

// no door sources at all.
if (_srcs isEqualTo []) exitWith {
    // a helicopter with no doors in its config is a doorless helicopter: the hummingbird, the pawnee, or a little bird
    // with the benches out. it is permanently open, and it should be, which is why this case is not zero.
    // a plane with no door animation is a sealed pressurised tube and stays sealed.
    if (_veh isKindOf "Helicopter") exitWith {1};
    0
};

// read every door source with all three commands.
// whichever command the author used, one of these answers. take the widest-open door, because one door slid back is
// enough to fill a cabin with 200 km/h of air.
private _max = 0;
{
    private _p = 0;
    private _a = _veh animationSourcePhase _x;  // authored as an animation source.
    if (_a isEqualType 0) then { _p = _p max _a; };
    private _b = _veh animationPhase _x;  // authored as a model animation.
    if (_b isEqualType 0) then { _p = _p max _b; };
    private _c = _veh doorPhase _x;  // the engine door system, which is ACE own default path.
    if (_c isEqualType 0) then { _p = _p max _c; };
    _max = _max max (_p max 0);
} forEach _srcs;

(_max min 1)
