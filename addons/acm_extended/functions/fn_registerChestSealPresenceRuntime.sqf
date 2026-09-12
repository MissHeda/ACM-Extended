/*
 * Phase 25 subsystem ownership: Chest-seal collaborative cursor/tool presence events.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

// chest seal: the live presence of other medics working the same chest. each participating client targets subscribed viewers with
// its normalized cursor position and held tool through fn_chestsealpresencesend. only clients
// with that patient's minigame open draws the fingers, seals and spears of the peers in real time, through
// fn_chestsealpresencerender. it is stored per patient, so several casualties can be worked at once with no
// crosstalk. an entry carries a timestamp and counts as stale after a moment, so a medic who closes the dialog
// fades out.
ACME_CS_presence = createHashMap;
["ACME_CS_presence", {
    params ["_patId", "_medId", "_medName", "_side", "_tool", "_pts", ["_burp", []]];
    if (!hasInterface) exitWith {};
    if (isNull (uiNamespace getVariable ["ACME_CS_DLG", displayNull])) exitWith {};
    private _viewed = uiNamespace getVariable ["ACME_CS_Patient", objNull];
    if (isNull _viewed || {netId _viewed != _patId}) exitWith {};
    private _peers = ACME_CS_presence getOrDefault [_patId, createHashMap, true];
    // stamp on arrival. the renderer treats an entry older than a moment as stale, which is how a medic who closes
    // the dialog or drops out fades off everyone else's chest.

    private _oldBurp = (_peers getOrDefault [_medId, []]) param [5, []];
    _peers set [_medId, [_medName, _side, _tool, _pts, diag_tickTime, _burp]];
    if !(_oldBurp isEqualTo _burp) then { [] call ACME_fnc_chestSealRender; };
}] call CBA_fnc_addEventHandler;

// a medic who closes the minigame is removed from everyone's presence map at once, rather than left to go
// stale.
["ACME_CS_presenceLeave", {
    params ["_patId", "_medId"];
    private _peers = ACME_CS_presence getOrDefault [_patId, createHashMap];
    _peers deleteAt _medId;
    if (count _peers == 0) then { ACME_CS_presence deleteAt _patId; };
    if (hasInterface && {!isNull (uiNamespace getVariable ["ACME_CS_DLG", displayNull])}) then { [] call ACME_fnc_chestSealRender; };
}] call CBA_fnc_addEventHandler;
