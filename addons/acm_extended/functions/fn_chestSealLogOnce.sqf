/* B45 per-patient/provider chest-seal activity-log dedupe.
 * Multiple wounds treated during one short working sequence should read as one action in the activity log.
 * Apply, burp and remove have independent cooldown keys so a burp never suppresses an apply (or vice versa).
 */
params ["_patient", ["_action", "", [""]], ["_message", "", [""]], ["_args", [], [[]]], ["_medic", objNull], ["_cooldown", -1, [0]]];
if (isNull _patient || {_action == ""} || {_message == ""}) exitWith {false};

if (_cooldown < 0) then {
    _cooldown = switch (toLowerANSI _action) do {
        case "apply": {missionNamespace getVariable ["ACME_chestSealApplyLogCooldown", 30]};
        case "burp": {missionNamespace getVariable ["ACME_chestSealBurpLogCooldown", 10]};
        case "remove": {missionNamespace getVariable ["ACME_chestSealRemoveLogCooldown", 10]};
        default {10};
    };
};

private _who = if (isNull _medic) then {"none"} else {netId _medic};
private _key = format ["%1:%2", toLowerANSI _action, _who];
private _times = _patient getVariable ["ACME_chestSealActivityLogTimes", createHashMap];
private _now = CBA_missionTime;
if ((_now - (_times getOrDefault [_key, -1e6])) < _cooldown) exitWith {false};
_times set [_key, _now];
_patient setVariable ["ACME_chestSealActivityLogTimes", _times, false];

[_patient, "activity", _message, _args] call ace_medical_treatment_fnc_addToLog;
true
