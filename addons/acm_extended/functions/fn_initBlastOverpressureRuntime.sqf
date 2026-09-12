// second TBI trigger: blast overpressure, a concussive primary blast injury that needs no head wound.
// every man gets an engine "Explosion" eh. a close enough detonation rolls a TBI scaled to the blast.
ACME_tbi_blastTriggerDamage = 0.15;  // explosion damage felt at the unit that can arm a blast TBI
ACME_tbi_blastChanceMin     = 0.25;  // chance at the trigger threshold. it rises to 1.0 with intensity.
// the detonation hook. this is what gives the blast solver the two things the engine Explosion event withholds:
// what went off, and where.
// it is two steps, because arma does not offer a single explosion event.
//   1. ProjectileCreated fires for every projectile, on the machine that fired it.
//   2. an Explode event handler on that projectile reports the detonation point when it goes off.
// so we attach step 2 only to things that can actually produce a blast, and let everything else through
// untouched.
// on the cost, because this does see every bullet. the explosive test is a config read, so the answer is cached
// by classname the first time each round type is seen and every later round of that type is a hashmap lookup. a
// rifle magazine costs thirty lookups and no config reads after the first shot.
// mines, satchels and anything detonated by a script do not always come through here. those still land on the
// engine Explosion handler above, which is exactly why that fallback is kept rather than removed.
if (hasInterface || isServer) then {
    ACME_blast_explosiveCache = createHashMap;
    addMissionEventHandler ["ProjectileCreated", {
        params ["_projectile"];
        if (isNull _projectile) exitWith {};
        // checked here rather than only downstream, so with the system off no explode handler is attached to any
        // projectile at all and the hook costs one variable read per round.
        if !(missionNamespace getVariable ["ACME_sys_blastOverpressure", false]) exitWith {};
        private _cls = typeOf _projectile;
        if (_cls == "") exitWith {};
        private _isBoom = ACME_blast_explosiveCache getOrDefault [_cls, -1];
        if (_isBoom isEqualTo -1) then {
            private _cfg = configFile >> "CfgAmmo" >> _cls;
            _isBoom = (getNumber (_cfg >> "explosive") > 0)
                   || {getNumber (_cfg >> "indirectHitRange") > 0.5};
            ACME_blast_explosiveCache set [_cls, _isBoom];
        };
        if !(_isBoom isEqualTo true) exitWith {};
        _projectile addEventHandler ["Explode", {
            params ["_proj", "_ePos", ""];
            // the position the engine hands us is AGL, so it is lifted to ASL before it goes anywhere near the
            // solver. every distance and every line-of-sight test in there is ASL, and mixing the two would put
            // the detonation underground on any map with terrain above sea level.
            private _asl = AGLToASL _ePos;
            ["ACME_blastDetonated", [_asl, typeOf _proj]] call CBA_fnc_globalEvent;
        }];
    }];
};

["ACME_blastDetonated", {_this call ACME_fnc_blastDetonated}] call CBA_fnc_addEventHandler;

["CAManBase", "init", {
    params ["_unit"];
    _unit addEventHandler ["Explosion", {
        params ["_unit", "_damage"];
        if (!local _unit) exitWith {};
        // stand down if the projectile hook already solved this blast properly. that path knows the charge and
        // the detonation point, so it computes cover, orientation and enclosure, and this one cannot. one wave is
        // one dose, so the better answer wins and the fallback keeps quiet.
        if ((CBA_missionTime - (_unit getVariable ["ACME_blast_solvedAt", -99999])) < 0.5) exitWith {};
        // one solver, then one apply. the handler decides nothing itself.
        // the engine gives us the damage felt at this unit and nothing else: no ammo class and no detonation
        // point. so the solver inverts arma's own falloff to estimate the range and assumes a grenade-sized
        // charge, which is documented in fn_blastsolve as an approximation.
        // it is accurate the moment a caller can supply the real values. anything that knows what went off and
        // where should call fn_blastsolve directly with the ammo class and the detonation position, and the
        // pressure, the enclosure and the line of sight are then all computed properly.
        private _res = [_unit, "", [], _damage] call ACME_fnc_blastSolve;
        [_unit, _res] call ACME_fnc_blastApply;
    }];
    // blood type lock, single player only and client-side. this stamps the chosen type on spawn, so it is set
    // before anything reads it. the periodic sweep below re-stamps after any ACM reset or regenerate.
    if (!isMultiplayer && {local _unit}) then {
        private _lock = missionNamespace getVariable ["ACME_bloodTypeLock", 0];
        if (_lock > 0) then {
            [_unit, [["bloodType", _lock - 1]], true] call ACM_circulation_fnc_setRuntimeState;
        };
    };
}, true] call CBA_fnc_addClassEventHandler;

// blood type lock, re-asserted periodically, single player only. ACM regenerates a random blood type inside
// its resetvariables, which fires on heal, respawn and other resets, so a one-shot stamp is not enough. this
// low-frequency sweep re-writes the locked type onto any local unit whose type has drifted. it does nothing
// when the setting is off or in multiplayer, where ACM's type is already UID-stable.
[{
    if (isMultiplayer) exitWith {};
    private _lock = missionNamespace getVariable ["ACME_bloodTypeLock", 0];
    if (_lock <= 0) exitWith {};
    private _want = _lock - 1;
    {
        if ((_x getVariable ["ACM_circulation_BloodType", -1]) != _want) then {
            [_x, [["bloodType", _want]], true] call ACM_circulation_fnc_setRuntimeState;
        };
    } forEach (allUnits select {local _x});
}, 3, []] call CBA_fnc_addPerFrameHandler;
