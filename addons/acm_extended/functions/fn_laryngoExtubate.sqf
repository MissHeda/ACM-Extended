// B120 deliberate extubation action.  This is the supported removal path for now: the 4-second treatment includes
// releasing securement and the cuff rather than hiding/refusing Extubate until the operator separately manipulates the airway view.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if !([_medic, "intubation", true] call ACME_fnc_procedureAllowed) exitWith {};
if !(_patient getVariable ["ACME_ETT_Inserted", false]) exitWith {};

// Clear the complete durable airway state atomically.  The dedicated action represents collar release, cuff
// deflation and withdrawal as one deliberate extubation procedure.
[_patient, false, false, false, false, true, false] call ACME_fnc_ettAirwayStateCommit;
[_patient, "placement", [0, 0, false]] call ACME_fnc_ettMigrationStateCommit;
[_patient, "obstruction", [false, 0]] call ACME_fnc_ettMigrationStateCommit;
_patient setVariable ["ACME_o2Drain_mainstem", 0, true];
_patient setVariable ["ACME_vent_complianceMult", 1, true];
_patient setVariable ["ACME_ETT_Trauma", false, true];
_patient setVariable ["ACME_ETT_Medic", objNull, true];
_patient setVariable ["ACME_ETT_Time", 0, true];

if (!isNull _medic) then {_medic addItem "ACME_ETTube";};
if (_patient getVariable ["ACME_vent_connected", false]) then {
    _patient setVariable ["ACME_vent_connected", false, true];
    _patient setVariable ["ACME_vent_driving", false, true];
};
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "airway", "Extubated: ET tube removed", []] call ace_medical_treatment_fnc_addToLog;
};
