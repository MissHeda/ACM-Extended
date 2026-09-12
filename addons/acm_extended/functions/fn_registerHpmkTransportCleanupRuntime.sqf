/*
 * Phase 25 subsystem ownership: Legacy HPMK network-blanket cleanup during patient transport.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

// B28 legacy cleanup. Wrapped casualties no longer carry a network blanket object at all, but a mission updated
// from an older build can still have ACME_hpmk_blanket set. Loading into a vehicle kills that stale anchor
// immediately. The current wrapped visual is client-local and disappears/reappears from the visual reconciler.
["ACME_hpmkKillBlanket", {
    if (!isServer) exitWith {};
    params ["_unit"];
    private _b = _unit getVariable ["ACME_hpmk_blanket", objNull];
    if (!isNull _b) then { deleteVehicle _b; };
    _unit setVariable ["ACME_hpmk_blanket", objNull, true];
}] call CBA_fnc_addEventHandler;
["ace_loadPersonEvent", {
    params ["_unit"];
    ["ACME_hpmkKillBlanket", [_unit]] call CBA_fnc_serverEvent;
}] call CBA_fnc_addEventHandler;
