#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Handle remove bag button.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ACM_circulation_fnc_TransfusionMenu_RemoveBag;
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(TransfusionMenu_DLG), displayNull];
private _ctrlBagPanel = _display displayCtrl IDC_TRANSFUSIONMENU_LEFTLISTPANEL;
private _selectionIndex = lbCurSel _ctrlBagPanel;

if (_selectionIndex < 0) exitWith {};

private _fnc_completeRemoval = {
    params ["_IVBags", "_IVBagsOnBodyPart", "_targetIndex", "_itemClassName", "_type", "_returnVolume", "_totalVolume"];

    private _returnedItem = [true];

    if (_returnVolume > 0) then {
        if (_type == "FBTK" && _returnVolume >= 250) then {
            // B96: the donor registry and unique bag ID are owned by the server. Client-side ID generation was
            // vulnerable to JIP clients having no FreshBloodList yet and to two medics allocating the same ID.
            // Delivery is acknowledged back to this medic by the server event registered in XEH_postInit.
            [QGVAR(requestFreshBloodBag), [ACE_player, GVAR(TransfusionMenu_Target), _returnVolume]] call CBA_fnc_serverEvent;
            _returnedItem = [true];
        } else {
            _returnedItem = [ACE_player, _itemClassName] call ACEFUNC(common,addToInventory);
        };
    } else {
        if (_type == "FBTK") then {
            _returnedItem = [ACE_player, (format ["ACM_FieldBloodTransfusionKit_%1", _totalVolume])] call ACEFUNC(common,addToInventory);
        };
    };

    private _returned = (_returnedItem select 0);

    if !(_returned) then {
        [ACELLSTRING(common,Inventory_Full), 1.5, ACE_player] call ACEFUNC(common,displayTextStructured);
    };

    _IVBagsOnBodyPart deleteAt _targetIndex;
    _IVBags set [GVAR(TransfusionMenu_Selected_BodyPart), _IVBagsOnBodyPart];

    GVAR(TransfusionMenu_Target) setVariable [QGVAR(IV_Bags), _IVBags, true];
};

private _targetIndex = (GVAR(TransfusionMenu_Selection_IVBags) select _selectionIndex) select 8;

private _IVBags = GVAR(TransfusionMenu_Target) getVariable [QGVAR(IV_Bags), createHashMap];
private _IVBagsOnBodyPart = _IVBags getOrDefault [GVAR(TransfusionMenu_Selected_BodyPart), []];

private _bagContents = +(_IVBagsOnBodyPart select _targetIndex);

_bagContents params ["_type", "_remainingVolume", "_accessType", "_accessSite", "_iv", "_bloodType", "_volume"];

private _returnVolume = if (_type == "FBTK") then {
    // FBTK is a collection bag, so generic IV-bag floor rounding is unsafe at the nominal boundary:
    // 499.9 mL used to become a 250 mL donor unit and 249.9 mL could become nothing even though the
    // menu rounded those values to 500/250 mL. Snap only the near-full boundary to the kit's authored
    // size; intentionally partial collections retain ACM's existing 250 mL floor behavior.
    private _fullTolerance = missionNamespace getVariable ["ACME_fbtk_fullToleranceMl", 1];
    if (!(_fullTolerance isEqualType 0) || {!finite _fullTolerance}) then {_fullTolerance = 1;};
    _fullTolerance = (_fullTolerance max 0) min 5;
    if (_remainingVolume >= ((_volume - _fullTolerance) max 0)) then {
        _volume
    } else {
        [_remainingVolume] call FUNC(getReturnVolume)
    }
} else {
    [_remainingVolume] call FUNC(getReturnVolume)
};

// A sub-250 mL FBTK returns the original empty kit. Use that real classname for the progress
// display instead of constructing the nonexistent ACM_FieldBloodTransfusionKit_0.
private _itemClassName = if (_type == "FBTK" && {_returnVolume <= 0}) then {
    format ["ACM_FieldBloodTransfusionKit_%1", _volume]
} else {
    [_type, _returnVolume, _bloodType] call FUNC(formatFluidBagName)
};
private _itemClassNameString = getText (configFile >> "CfgWeapons" >> _itemClassName >> "displayName");

private _funcParams = [_IVBags, _IVBagsOnBodyPart, _targetIndex, _itemClassName, _type, _returnVolume, _volume];

[[ACE_player, GVAR(TransfusionMenu_Target), _type, _returnVolume, _bloodType, _fnc_completeRemoval, _funcParams], {
    params ["_medic", "_patient", "_type", "_returnVolume", "_bloodType", "_fnc_completeRemoval", "_funcParams"];

    _funcParams call _fnc_completeRemoval;

    private _fluidBagString = "";

    if (_type == "FBTK") then {
        _fluidBagString = format ["%1 %2ml", "FBTK", _returnVolume];
    } else {
        _fluidBagString = [([_type, _returnVolume, _bloodType, true] call FUNC(formatFluidBagName))] call FUNC(getFluidBagString);
    };
    [_patient, "activity", LSTRING(TransfusionMenu_RemoveBag_ActionLog), [[_medic, false, true] call ACEFUNC(common,getName), (_fluidBagString), ([GVAR(TransfusionMenu_Selected_BodyPart)] call EFUNC(core,getBodyPartString))]] call ACEFUNC(medical_treatment,addToLog);
    closeDialog 0;

    [{
        params ["_medic", "_patient"];

        [_medic, _patient, GVAR(TransfusionMenu_Selected_BodyPart)] call FUNC(openTransfusionMenu);
    }, [_medic, _patient], 0.05] call CBA_fnc_waitAndExecute;
}, {
    params ["_medic", "_patient"];
    closeDialog 0;

    [_medic, _patient, GVAR(TransfusionMenu_Selected_BodyPart)] call FUNC(openTransfusionMenu);
}, (format [LLSTRING(TransfusionMenu_RemoveBag_Progress), _itemClassNameString]), 2.5] call EFUNC(core,progressBarAction);
