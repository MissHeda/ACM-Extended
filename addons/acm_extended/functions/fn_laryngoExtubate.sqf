// extubate.
// call it as [_medic, _patient] call ACME_fnc_laryngoExtubate.
// this is the only way a secured airway comes back out. nothing inside the laryngoscopy screen can disturb a tube
// once it is in: the tray locks, the tube cannot be picked back up, and the collar cannot be unclipped. that is
// deliberate, and it is also how it works in life. a secured tube is not something you fiddle with by accident.
// taking it out gives the tube back and hands the airway straight back to the casualty, who now has whatever airway
// they had before it went in, which for most of them is none.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if !([_medic, "intubation", true] call ACME_fnc_procedureAllowed) exitWith {};
if (!(_patient getVariable ["ACME_ETT_Inserted", false])) exitWith {};
if (_patient getVariable ["ACME_ETT_Secured", false]) exitWith {
    ["Remove the tube collar in Airway View before extubating.", 2.5, _medic] call ace_common_fnc_displayTextStructured;
};
if (_patient getVariable ["ACME_ETT_CuffInflated", false]) exitWith {
    ["Deflate the ET cuff in Airway View before extubating.", 2.5, _medic] call ace_common_fnc_displayTextStructured;
};

[_patient, false, false, false, false, true, false] call ACME_fnc_ettAirwayStateCommit;
[_patient, "placement", [1, "__KEEP__", false]] call ACME_fnc_ettMigrationStateCommit;
_patient setVariable ["ACME_o2Drain_mainstem", 0, true];
_patient setVariable ["ACME_vent_complianceMult", 1, true];
[_patient, "obstruction", [false]] call ACME_fnc_ettMigrationStateCommit;
_patient setVariable ["ACME_ETT_Trauma", false, true];
_patient setVariable ["ACME_ETT_Medic", objNull, true];
_patient setVariable ["ACME_ETT_Time", 0, true];

// the tube itself is not reusable once it has been in an airway, and the medic gets one back so the workflow does
// not dead-end on a single mistake in the field.
if (!isNull _medic) then { _medic addItem "ACME_ETTube"; };

// off the ventilator: there is nothing to ventilate through any more.
if (_patient getVariable ["ACME_vent_connected", false]) then {
    _patient setVariable ["ACME_vent_connected", false, true];
    _patient setVariable ["ACME_vent_driving", false, true];
};

// the body-diagram marker is not refreshed from here. fn_updateettubeimage takes a controls group and a target and
// is driven by ace_medical_gui_updateBodyImage, so calling it with the patient handed an object where a control
// was expected, which is the error in the RPT. the menu repaints itself and picks the change up.

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "airway", "Extubated: ET tube removed", []] call ace_medical_treatment_fnc_addToLog;
};
