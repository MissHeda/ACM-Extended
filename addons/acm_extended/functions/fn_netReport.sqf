// Network audit candidate NA1. Machine-local HELPER CALL counters, not wire statistics.
// Enable independently on server, relevant player clients and headless clients:
// ACME_net_sent = createHashMap; ACME_net_saved = createHashMap;
// ACME_net_since = diag_tickTime; ACME_net_count = true;
// Run a representative scenario, then [] call ACME_fnc_netReport on EACH machine.
// Raw public setVariable, CBA events and remoteExec are NOT counted here.
// Return shape retained: [publicationRequestsPerSecond, suppressedCallsPerSecond].
private _sent = missionNamespace getVariable ["ACME_net_sent", createHashMap];
private _saved = missionNamespace getVariable ["ACME_net_saved", createHashMap];
private _since = missionNamespace getVariable ["ACME_net_since", -1];
private _elapsed = if (_since >= 0) then { (diag_tickTime - _since) max 0.001 } else { 1 };
private _names = keys _sent;
{ _names pushBackUnique _x; } forEach (keys _saved);
private _rows = [];
private _totalSent = 0;
private _totalSaved = 0;
{
    private _s = _sent getOrDefault [_x, 0];
    private _k = _saved getOrDefault [_x, 0];
    _totalSent = _totalSent + _s;
    _totalSaved = _totalSaved + _k;
    _rows pushBack [_s + _k, _x, _s, _k];
} forEach _names;
_rows sort false;
missionNamespace setVariable ["ACME_netReportDetails", [
    missionNamespace getVariable ["ACME_net_count", false], _elapsed, _rows
], false];
[(_totalSent / _elapsed), (_totalSaved / _elapsed)]
