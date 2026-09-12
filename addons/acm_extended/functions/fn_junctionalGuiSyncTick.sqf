/*
    Local medical-GUI synchronizer for junctional state.
    Patient variables are already synchronized by their authoritative writers. This adds no network writes.
*/
disableSerialization;
private _display = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];
if (isNull _display) exitWith {uiNamespace setVariable ["ACME_junctionalGuiSig", []];};
private _target = missionNamespace getVariable ["ace_medical_gui_target", objNull];
if (isNull _target) exitWith {};
private _sig = [
    _target,
    alive _target,  // refresh the injury description at death without hiding the wound
    _target getVariable ["ACME_Junc_leftarm", ""],
    _target getVariable ["ACME_Junc_rightarm", ""],
    _target getVariable ["ACME_Junc_leftleg", ""],
    _target getVariable ["ACME_Junc_rightleg", ""],
    _target getVariable ["ACME_AAJT_inguinal", false],
    _target getVariable ["ACME_AAJT_axillaleft", false],
    _target getVariable ["ACME_AAJT_axillaright", false]
];
if (_sig isEqualTo (uiNamespace getVariable ["ACME_junctionalGuiSig", []])) exitWith {};
uiNamespace setVariable ["ACME_junctionalGuiSig", _sig];
private _selection = missionNamespace getVariable ["ace_medical_gui_selectedBodyPart", -1];
private _body = _display displayCtrl 6000;
if (!isNull _body && {!isNil "ace_medical_gui_fnc_updateBodyImage"}) then {[_body, _target, _selection] call ace_medical_gui_fnc_updateBodyImage;};
private _injuries = _display displayCtrl 1410;
if (!isNull _injuries && {!isNil "ace_medical_gui_fnc_updateInjuryList"}) then {[_injuries, _target, _selection] call ace_medical_gui_fnc_updateInjuryList;};
