/* Per-device absolute limits. Old alertMVlow/high were unused percentages.
   New names make legacy saves fall back explicitly instead of becoming 50 or 145 L/min. */
params [["_patient", objNull, [objNull]]];
private _lowDefault = missionNamespace getVariable ["ACME_vent_alertMVlowLpmDefault", 3.0];
private _highDefault = missionNamespace getVariable ["ACME_vent_alertMVhighLpmDefault", 10.0];
private _low = if (isNull _patient) then {_lowDefault} else {_patient getVariable ["ACME_vent_alertMVlowLpm", _lowDefault]};
private _high = if (isNull _patient) then {_highDefault} else {_patient getVariable ["ACME_vent_alertMVhighLpm", _highDefault]};
if (!(_low isEqualType 0)) then {_low = 3.0;};
if (!(_high isEqualType 0)) then {_high = 10.0;};
if (!finite _low) then {_low = 3.0;};
if (!finite _high) then {_high = 10.0;};
_low = (round ((_low max 0 min 29.5) * 10)) / 10;
_high = (round ((_high max (_low + 0.5) min 30) * 10)) / 10;
[_low, _high]
