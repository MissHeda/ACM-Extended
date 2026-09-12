// the zeus and eden module entry point for "Spawn Megacode Kelly". the engine runs this with the placed module
// logic. it spawns the dummy at the position of the logic, then removes the logic so only the manikin remains.
// _this is [_logic, _units, _activated], the Module_F convention.
params ["_logic"];
if (isNull _logic) exitWith {};
if (!isServer) exitWith {};  // spawn authoritatively on the server; the unit syncs to clients

private _pos = getPosATL _logic;
private _dir = getDir _logic;
// a game-logic module can fire its init during object initialization, before CBA and ACE have finished their
// per-mission init. in this listen-server vr mission the preinit and object-init run at about t, and CBA postinit
// lands a couple of seconds later.
// fn_megacodespawn calls CBA_fnc_addPerFrameHandler, globalevent and ace_common_fnc_displayTextStructured, which
// then error on undefined globals if it runs that early. so defer to the scheduler, using a vanilla spawn rather
// than a CBA call, so it is safe even before CBA is up, and wait until those globals actually exist. the scheduler
// only runs once the mission is live, by which point the CBA and ACE postinit have run.
[_pos, _dir, _logic] spawn {
    params ["_pos", "_dir", "_logic"];
    waitUntil {
        (time > 0)
        && {!isNil "cba_common_perFrameHandlerArray"}
        && {!isNil "cba_events_eventNamespace"}
        && {!isNil "ace_common_fnc_displayTextStructured"}
    };
    [_pos, _dir] call ACME_fnc_megacodeSpawn;
    if (!isNull _logic) then { deleteVehicle _logic };
};
