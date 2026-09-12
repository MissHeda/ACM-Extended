#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * GUI-owned integration point for temporarily pausing ACE medical-menu refresh while a procedure display owns input.
 */
private _pfh = missionNamespace getVariable ["ace_medical_gui_menuPFH", -1];
if (_pfh isEqualType 0 && {_pfh >= 0}) then {
    _pfh call CBA_fnc_removePerFrameHandler;
    missionNamespace setVariable ["ace_medical_gui_menuPFH", -1];
    true
} else {
    false
}
