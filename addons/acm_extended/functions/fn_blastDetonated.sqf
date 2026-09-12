// a detonation happened, and this time we know what and where.
// it is raised on every machine as the CBA event "ACME_blastDetonated", with [_pos, _ammo], where _pos is the
// detonation point in ASL and _ammo is the ammo classname.
// each machine solves for the men that are local to it, because the medical state has to be written where the
// unit lives.
//
// why the event is global rather than server-only.
// the projectile is local to whoever fired it, so only that machine sees it explode. the casualties can be on any
// machine. one small broadcast per explosion is far cheaper than every machine tracking every projectile, and it
// means the solve runs where the writes are legal.
params ["_pos", ["_ammo", ""]];
if ((count _pos) < 3) exitWith {};
// the system toggle, read live, so unticking blast overpressure in addon options stops it immediately and
// completely with no mission restart. it is off by default while it is in beta.
if !(missionNamespace getVariable ["ACME_sys_blastOverpressure", false]) exitWith {};

// how far this blast can possibly matter.
// the overpressure relation is only meaningful out to a scaled distance of about 15, and past that the wave is
// down in the single-digit kPa where nothing in the injury model responds. so the search radius is derived from
// the charge rather than being a fixed number: a grenade searches a few meters and a heavy shell searches tens.
// it is capped so a mission with an enormous scripted charge cannot make this sweep the whole map.
private _wKg = 0;
if (_ammo != "") then {
    private _cfg = configFile >> "CfgAmmo" >> _ammo;
    if (isClass _cfg) then {
        private _ovr = missionNamespace getVariable ["ACME_blast_tntOverride", createHashMap];
        _wKg = _ovr getOrDefault [_ammo, 0];
        if (_wKg <= 0) then {
            _wKg = (getNumber (_cfg >> "indirectHit")) * (missionNamespace getVariable ["ACME_blast_tntPerIndirectHit", 0.005]);
        };
    };
};
if (_wKg <= 0) then { _wKg = 0.18 };
private _radius = ((15 * (_wKg ^ (1/3))) min (missionNamespace getVariable ["ACME_blast_maxRadius", 150])) max 3;

{
    private _u = _x;
    if (local _u && {alive _u} && {_u isKindOf "CAManBase"}) then {
        private _res = [_u, _ammo, _pos, 0] call ACME_fnc_blastSolve;
        // stamp the unit so the engine Explosion handler, which fires for the same blast with far less
        // information, knows a proper solve has already been done and stands down. without this the casualty is
        // dosed twice for one wave: once properly and once from the crude fallback.
        _u setVariable ["ACME_blast_solvedAt", CBA_missionTime];
        [_u, _res] call ACME_fnc_blastApply;
    };
} forEach ((ASLToAGL _pos) nearEntities ["CAManBase", _radius]);

// the search position is converted back out of ASL first.
// the solver works entirely in ASL, because getposasl and lineintersectssurfaces do, and the detonation point
// arrives here in ASL for that reason. nearentities does not: it takes a world position. handing it ASL puts the
// center of the search sphere as far above the ground as the terrain is above sea level, so on any map that is
// not at sea level it quietly finds nobody and the whole system does nothing at all.
// that is exactly what happened on the first test: the hook fired, the event crossed the network, and the search
// matched zero men.
