// the ventilator logbook. the real ventway sparrow keeps a chronological record of the use of the device, meaning
// the alarms and alerts that fired and the interactions of the operator, such as settings changed and actions
// taken, so a technician can reconstruct what the machine did and when, for troubleshooting and maintenance. this
// is our version of it.
// the scope is per device. the device is tracked per medic, because ACME_vent_devicePatient lives on the operator,
// so the log lives on the operator, ACE_player. a player-namespace variable is wiped when the mission or server
// restarts, which is exactly the reset-every-restart the logbook is supposed to have, so no explicit clear is
// needed.
// an entry is [_clockstring, _category, _text].
// _clockstring is the in-mission wall-clock "HH:MM", from daytime, so it reads like the timestamps of the device.
// _category is "ALARM", "ALERT", "USER" or "SYSTEM", and it drives the little tag color on the screen.
// _text is the human-readable line, such as "Mode -> SIMV VC PS" or "APNEA".
// call it as ["USER", "Mode -> SIMV VC PS"] call ACME_fnc_ventLogbookAdd.
params [["_category", "SYSTEM"], ["_text", ""]];
if (!hasInterface) exitWith {};
if (_text isEqualTo "") exitWith {};

// the in-mission clock as hh:mm. daytime is hours as a float, 0 to 24, so split it into whole hours and minutes and
// pad.
private _h = floor daytime;
private _m = floor ((daytime - _h) * 60);
private _hs = if (_h < 10) then {format ["0%1", _h]} else {str _h};
private _ms = if (_m < 10) then {format ["0%1", _m]} else {str _m};
private _clock = format ["%1:%2", _hs, _ms];

private _log = ACE_player getVariable ["ACME_vent_logbook", []];

// de-dupe consecutive identical events: an alarm that stays active for a minute should log once when it starts
// rather than once per tick. only the newest entry is checked, so the same alarm recurring later still logs
// again.
if (count _log > 0) then {
    (_log select 0) params ["_lastClock", "_lastCat", "_lastText"];
    if (_lastCat isEqualTo _category && {_lastText isEqualTo _text}) exitWith {};
};

// newest first, at index 0, so the screen shows the most recent at the top without reversing on every open.
_log = [[_clock, _category, _text]] + _log;

// cap the buffer. a real logbook is bounded, and 200 lines is plenty to troubleshoot a session and keeps the array
// cheap to page through on the screen.
private _cap = missionNamespace getVariable ["ACME_vent_logbookCap", 200];
if (count _log > _cap) then { _log resize _cap; };

ACE_player setVariable ["ACME_vent_logbook", _log];
