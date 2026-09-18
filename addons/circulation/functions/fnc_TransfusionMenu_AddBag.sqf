#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Handle add bag button.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ACM_circulation_fnc_TransfusionMenu_AddBag;
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(TransfusionMenu_DLG), displayNull];

private _ctrlInventoryPanel = _display displayCtrl IDC_TRANSFUSIONMENU_RIGHTLISTPANEL;

private _targetIndex = lbCurSel _ctrlInventoryPanel;

if (_targetIndex < 0) exitWith {};

((_ctrlInventoryPanel lbData _targetIndex) splitString "|") params ["_itemClassname", "_actionClassname"];

private _medic = ACE_player;
private _patient = GVAR(TransfusionMenu_Target);

// FBTK is a donor-collection circuit, not an infusion product. The circulation model deliberately
// refuses to draw donor blood through IO. Reject it before inventory consumption so the kit can never
// be hung on a line that will sit at 0 mL forever and look broken to the provider.
private _isFBTK = (_itemClassname in FBTK_ARRAY) || {_actionClassname in FBTK_ARRAY_DATA};
if (_isFBTK && {!GVAR(TransfusionMenu_SelectIV)}) exitWith {
    ["FBTK blood collection requires IV access. It cannot collect through IO.", 3, ACE_player, 13] call ACEFUNC(common,displayTextStructured);
};

private _validAccess = [
    _patient,
    GVAR(TransfusionMenu_Selected_BodyPart),
    GVAR(TransfusionMenu_SelectIV),
    GVAR(TransfusionMenu_Selected_AccessSite)
] call ACME_fnc_transfusionAccessValid;
if (!_validAccess) exitWith {
    ["Establish and select an IV or IO before hanging fluid.",2.5,ACE_player,13] call ACEFUNC(common,displayTextStructured);
};

private _vehicle = objectParent _medic;

private _target = [_medic, _patient, _vehicle] select GVAR(TransfusionMenu_Selected_Inventory);

// A fresh whole-blood item is only safe to consume once its donor metadata is present locally. JIP/MP registry
// synchronization can trail the physical inventory item briefly. Never remove the bag first and discover that its
// ABO/time metadata is missing afterward. Ask the server to resync and leave the item untouched.
private _itemCfg = configFile >> "CfgWeapons" >> _itemClassname;
private _freshMetadataReady = true;
if ((getNumber (_itemCfg >> "uniqueBag")) > 0) then {
    private _parts = _itemClassname splitString "_";
    private _freshID = parseNumber (_parts param [3, "-1"]);
    private _freshEntry = [_freshID] call FUNC(getFreshBloodEntry);
    _freshMetadataReady = _freshEntry isEqualType [] && {count _freshEntry >= 3};
};
if (!_freshMetadataReady) exitWith {
    [QGVAR(requestFreshBloodRegistry), [ACE_player]] call CBA_fnc_serverEvent;
    ["Donor blood bag data is still synchronizing. Reopen the transfusion menu in a moment.", 2.5] call ACEFUNC(common,displayTextStructured);
};

if (GVAR(TransfusionMenu_Selected_Inventory) == 2) then {
    _vehicle addItemCargoGlobal [_itemClassname, -1];
} else {
    _target removeItem _itemClassname;
};

private _itemClassNameString = getText (configFile >> "CfgWeapons" >> _itemClassname >> "displayName");

[[_medic, _patient, _target, _itemClassname, _actionClassname, _vehicle], {
    params ["_medic", "_patient", "_target", "_itemClassname", "_actionClassname"];

    [_medic, _patient, GVAR(TransfusionMenu_Selected_BodyPart), _actionClassname, objNull, _itemClassname, GVAR(TransfusionMenu_SelectIV), GVAR(TransfusionMenu_Selected_AccessSite)] call ACEFUNC(medical_treatment,ivBag);
    closeDialog 0;

    [{
        params ["_medic", "_patient"];

        [_medic, _patient, GVAR(TransfusionMenu_Selected_BodyPart)] call FUNC(openTransfusionMenu);
    }, [_medic, _patient], 0.05] call CBA_fnc_waitAndExecute;
}, {
    params ["_medic", "_patient", "_target", "_itemClassname", "", "_vehicle"];

    if (GVAR(TransfusionMenu_Selected_Inventory) == 2) then {
        _vehicle addItemCargoGlobal [_itemClassname, 1];
    } else {
        [_target, _itemClassname] call ACEFUNC(common,addToInventory);
    };
    closeDialog 0;

    [_medic, _patient, GVAR(TransfusionMenu_Selected_BodyPart)] call FUNC(openTransfusionMenu);
}, (format [LLSTRING(TransfusionMenu_AddBag_Progress), _itemClassNameString]), 5] call EFUNC(core,progressBarAction);
