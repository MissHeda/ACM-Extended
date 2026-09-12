// the SYNC key handler. it arms or disarms synchronized-cardioversion mode on the current patient of the monitor,
// ACM_circulation_AED_Monitor_Target.
// it repaints the green led immediately, and the flag pfh started in setup picks up the armed state on its next
// tick.
private _tgt = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
if (isNull _tgt) exitWith {};

private _armed = !(_tgt getVariable ["ACME_sync_armed", false]);
_tgt setVariable ["ACME_sync_armed", _armed, true];

private _display = uiNamespace getVariable ["ACM_circulation_AEDMonitor_DLG", displayNull];
if (!isNull _display) then {
    private _led = _display displayCtrl 7283201;
    if (!isNull _led) then { _led ctrlShow _armed; };
};

[format ["SYNC %1", ["DISARMED", "ARMED"] select _armed], 2] call ace_common_fnc_displayTextStructured;
