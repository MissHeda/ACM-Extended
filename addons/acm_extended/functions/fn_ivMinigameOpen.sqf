// open the iv placement mini-game for a chosen limb and access site.
// call it as [_medic, _patient, _bodyPart, _site] call ACME_fnc_ivMinigameOpen.
// _bodyPart is "leftarm", "rightarm", "leftleg" or "rightleg".
// _site is "upper", "middle" or "lower".
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_bodyPart", "leftarm", [""]], ["_site", "lower", [""]]];
if (!hasInterface) exitWith {};
if (isNull _patient) exitWith {};

private _data = [_bodyPart, _site] call ACME_fnc_ivSiteData;
if (_data isEqualTo []) exitWith {
    [format ["No IV site mapped for %1 / %2.", _bodyPart, _site], 2, ACE_player] call ace_common_fnc_displayTextStructured;
};

// Close using the OLD context before replacing any UI patient variables.
private _old = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (!isNull _old) then {_old closeDisplay 2;};
// Only the patient and page captured for this launch may become the return page.
// A scripted/interaction-menu launch has no previous page, so use its own body part.
private _launchPart = if ((toLower _bodyPart) == "ej") then {"head"} else {toLower _bodyPart};
private _selection = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find _launchPart;
if (_selection < 0) then {_selection = 0;};
private _return = [_patient, "medication", _selection];
private _prepared = uiNamespace getVariable ["ACME_IV_PreparedMenu", []];
uiNamespace setVariable ["ACME_IV_PreparedMenu", []];
if (count _prepared == 6 && {(_prepared select 0) isEqualTo _medic}
    && {(_prepared select 1) isEqualTo _patient} && {(_prepared select 2) isEqualTo _launchPart}
    && {(_prepared select 4) == ([_patient] call ACME_fnc_clinicalEpoch)}
    && {CBA_missionTime - (_prepared select 5) >= 0} && {CBA_missionTime - (_prepared select 5) <= 5}) then {
    _return = +(_prepared select 3);
} else {
    private _menu = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
    if (!isNull _menu && {(missionNamespace getVariable ["ace_medical_gui_target", objNull]) isEqualTo _patient}) then {
        _return = [_patient, missionNamespace getVariable ["ace_medical_gui_selectedCategory", "medication"],
            missionNamespace getVariable ["ace_medical_gui_selectedBodyPart", _selection]];
    };
};
uiNamespace setVariable ["ACME_IV_ReturnMenu", _return];
uiNamespace setVariable ["ACME_medicalReturnSerial", (uiNamespace getVariable ["ACME_medicalReturnSerial", 0]) + 1];
private _serial = (uiNamespace getVariable ["ACME_IV_Serial", 0]) + 1;
uiNamespace setVariable ["ACME_IV_Serial", _serial];
uiNamespace setVariable ["ACME_IV_Session", [_patient, [_patient] call ACME_fnc_clinicalEpoch, _serial]];
uiNamespace setVariable ["ACME_IV_Medic", _medic];
uiNamespace setVariable ["ACME_IV_Patient", _patient];
uiNamespace setVariable ["ACME_IV_BodyPart", toLower _bodyPart];
uiNamespace setVariable ["ACME_IV_Site", toLower _site];
[_patient, "ui:iv:" + str clientOwner, true] call ACME_fnc_ecgJostleRequest;
// This dialog supplies its own return. Suppress ACE's treatment-success reopen.
ace_medical_gui_pendingReopen = false;

// close the medical menu first, so it is not fighting the dialog. it mirrors the chest-seal open.
private _med = findDisplay 38580;
if (!isNull _med) then { _med closeDisplay 2; };
[{if ([_this] call ACME_fnc_ivUiValid) then {["ACME_IVMinigame_Dialog"] call ACME_fnc_minigameOpen;};}, uiNamespace getVariable ["ACME_IV_Session", []]] call CBA_fnc_execNextFrame;
