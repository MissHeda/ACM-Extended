// Check Airway only. Descendants inherit callbackStart from CheckAirway in ACM, so gate on the exact
// treatment classname before starting a persistent pose owner. The requested work motion is supplied by
// AinvPknlMstpSnonWrflDr_medic4_old directly and fills the native 2.5 s check window.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "", [""]],
    ["_classname", "", [""]]
];
if (toLower _classname != "checkairway") exitWith {};
[_medic, "airway", 2.5] call ACME_fnc_treatmentPoseStart;
