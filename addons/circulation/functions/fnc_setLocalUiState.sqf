#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Circulation-owned writer for the local missionNamespace state backing circulation UI workflows.
 */
params [["_changes", [], [[]]]];
private _applied = 0;
{
    if (_x isEqualType [] && {count _x >= 2}) then {
        _x params ["_field", "_value"];
        switch (_field) do {
            case "transfusionSelectIV": { missionNamespace setVariable [QGVAR(TransfusionMenu_SelectIV), _value]; _applied = _applied + 1; };
            case "transfusionSelectedBodyPart": { missionNamespace setVariable [QGVAR(TransfusionMenu_Selected_BodyPart), _value]; _applied = _applied + 1; };
            case "transfusionSelectedAccessSite": { missionNamespace setVariable [QGVAR(TransfusionMenu_Selected_AccessSite), _value]; _applied = _applied + 1; };
            case "medicationVialList": { missionNamespace setVariable [QGVAR(MedicationVialList), _value]; _applied = _applied + 1; };
            case "syringeDrawInventorySelection": { missionNamespace setVariable [QGVAR(SyringeDraw_InventorySelection), _value]; _applied = _applied + 1; };
        };
    };
} forEach _changes;
_applied
