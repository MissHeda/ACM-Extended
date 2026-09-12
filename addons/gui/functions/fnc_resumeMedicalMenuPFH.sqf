#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * GUI-owned integration point for restoring ACE medical-menu refresh after a procedure display closes.
 */
if (isNull (uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull])) exitWith {false};
if !((missionNamespace getVariable ["ace_medical_gui_menuPFH", -1]) isEqualTo -1) exitWith {false};
if (isNil "ace_medical_gui_fnc_menuPFH") exitWith {false};
missionNamespace setVariable ["ace_medical_gui_menuPFH", ([ace_medical_gui_fnc_menuPFH, 0, []] call CBA_fnc_addPerFrameHandler)];
true
