/* Total exhaled minute volume in L/min. Alarm and panel share this read.
   Alveolar adequacy in fn_ventDriveTick.sqf remains a separate physiology value. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {0};
private _exact = if (_patient getVariable ["ACME_vent_driving", false]) then {
    _patient getVariable ["ACME_vent_mvDelivered", -1]
} else {-1};
// Exit the function itself, not a nested `then` scope that falls through below.
if (_exact isEqualType 0 && {finite _exact} && {_exact >= 0}) exitWith { _exact };
private _rr = _patient getVariable ["ACM_breathing_RespirationRate", 0];
private _vte = _patient getVariable ["ACME_vent_vte", 0];
if (!(_rr isEqualType 0) || {!(_vte isEqualType 0)}) exitWith {0};
if (!finite _rr || {!finite _vte}) exitWith {0};
((_rr max 0) * (_vte max 0)) / 1000
