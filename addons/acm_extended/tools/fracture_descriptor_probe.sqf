// On-demand snapshot. Returns and stores local data; does not write patient state or the RPT.
private _out = [];
// Read-only local diagnostic. It does not inspect, treat or write patient state.
// Example: [cursorObject, "leftarm"] execVM "\acm_extended\tools\fracture_descriptor_probe.sqf";
params [["_patient", cursorObject, [objNull]], ["_part", "leftarm", [""]]];
private _cfg = configFile >> "ace_medical_treatment_actions" >> "InspectForFracture";
private _fields = ["callbackSuccess", "condition", "medicRequired", "displayName", "displayNameProgress"];
private _config = _fields apply {[_x, getText (_cfg >> _x)]};
_config pushBack ["treatmentTime", getNumber (_cfg >> "treatmentTime")];
_config pushBack ["allowedSelections", getArray (_cfg >> "allowedSelections")];
_out pushBack format ["[ACME NA8 fracture probe] config=%1; hc=%2; nativeMissing=%3; callbackMissing=%4", _config, ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true), isNil "ACM_disability_fnc_inspectForFracture", isNil "ACME_fnc_inspectForFracture"];
if (isNull _patient) exitWith {_out pushBack "No patient under cursor."; missionNamespace setVariable ["ACME_fractureProbeResult", _out, false]; _out};
private _index = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find (toLowerANSI _part);
private _state = ["ACM_disability_Fracture_State", "ace_medical_bodyPartDamage", "ACM_disability_SplintStatus", "ace_medical_fractures", "ACM_disability_Fracture_Prepared"] apply {[_x, _patient getVariable [_x, []]]};
_out pushBack format ["[ACME NA8 fracture probe] patient=%1; selectedIndex=%2; localHere=%3; state=%4", _patient, _index, local _patient, _state];

missionNamespace setVariable ["ACME_fractureProbeResult", _out, false];
_out
