// debug: induce or clear over-resuscitation pulmonary edema on a patient, without having to actually dump liters of
// crystalloid.
// it sets a debug-force flag that the blood-volume override pins the Overload_Volume of ACM to, so the edema state,
// meaning the auscultation crackles, the capped hypoxia and the tachypnea, holds until toggled off.
// clearing drops the overload to 0 and resets the lung state, so the patient recovers immediately.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};

private _on = _patient getVariable ["ACME_edema_debugForce", false];

if (_on) then {
    _patient setVariable ["ACME_edema_debugForce", false, true];
    _patient setVariable ["ACME_edema_crackles", false, true];
    [_patient, [["overloadVolume", 0]], true] call ACM_circulation_fnc_setRuntimeState;
    [_patient, [["stethoscopeLungState", [0,0]]], true] call ACM_breathing_fnc_setRuntimeState;
    ["Over-resuscitation cleared (debug).", 2, _medic] call ace_common_fnc_displayTextStructured;
} else {
    _patient setVariable ["ACME_edema_debugForce", true, true];
    _patient setVariable ["ACME_edema_crackles", true, true];
    [_patient, [["overloadVolume", (missionNamespace getVariable ["ACME_edema_debugInduceVolume", 2.0])]], true] call ACM_circulation_fnc_setRuntimeState;
    ["Over-resuscitation induced (debug): pulmonary edema. Auscultate for crackles.", 3, _medic] call ace_common_fnc_displayTextStructured;
    // the activity-log line is removed, because it revealed the condition of the patient.
};
