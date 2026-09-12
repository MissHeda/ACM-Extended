/* Capture the launching medical page before ACE replaces it with its progress bar.
   Presentation only: placement and other providers' treatment state are untouched. */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_bodyPart", "head", [""]]];
if (!hasInterface || {isNull _patient}) exitWith {};
private _selection = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find (toLower _bodyPart);
if (_selection < 0) then {_selection = 0;};
private _category = "medication";
private _menu = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
if (!isNull _menu && {(missionNamespace getVariable ["ace_medical_gui_target", objNull]) isEqualTo _patient}) then {
    _category = missionNamespace getVariable ["ace_medical_gui_selectedCategory", "medication"];
    _selection = missionNamespace getVariable ["ace_medical_gui_selectedBodyPart", _selection];
};
uiNamespace setVariable ["ACME_IV_PreparedMenu", [_medic, _patient, toLower _bodyPart,
    [_patient, _category, _selection], [_patient] call ACME_fnc_clinicalEpoch, CBA_missionTime]];
// Starting a new procedure cancels any older deferred menu return.
uiNamespace setVariable ["ACME_medicalReturnSerial", (uiNamespace getVariable ["ACME_medicalReturnSerial", 0]) + 1];
