#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Handle stop transfusion button.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ACM_circulation_fnc_TransfusionMenu_ToggleIVFlow;
 *
 * Public: No
 */

private _patient = GVAR(TransfusionMenu_Target);
private _partIndex = ALL_BODY_PARTS find GVAR(TransfusionMenu_Selected_BodyPart);
private _validAccess = [_patient,GVAR(TransfusionMenu_Selected_BodyPart),GVAR(TransfusionMenu_SelectIV),GVAR(TransfusionMenu_Selected_AccessSite)] call ACME_fnc_transfusionAccessValid;
if (_partIndex < 0 || {!_validAccess}) exitWith {
    ["No established IV/IO is selected.",2,ACE_player,13] call ACEFUNC(common,displayTextStructured);
};

if (GVAR(TransfusionMenu_SelectIV)) then {
    private _flowArray = GET_IV_FLOW(GVAR(TransfusionMenu_Target));
    private _flowArrayBodyPart = +(_flowArray select _partIndex);

    private _newFlow = _flowArrayBodyPart select GVAR(TransfusionMenu_Selected_AccessSite);

    if (_newFlow > 0) then {
        _newFlow = 0;
    } else {
        _newFlow = 1;
    };

    _flowArrayBodyPart set [GVAR(TransfusionMenu_Selected_AccessSite), _newFlow];
    _flowArray set [_partIndex, _flowArrayBodyPart];

    GVAR(TransfusionMenu_Target) setVariable [VAR_FLUIDBAG_FLOW_IV, _flowArray, true];
} else {
    private _flowArray = GET_IO_FLOW(GVAR(TransfusionMenu_Target));

    private _newFlow = (_flowArray select _partIndex);

    if (_newFlow > 0) then {
        _newFlow = 0;
    } else {
        _newFlow = 1;
    };

    _flowArray set [_partIndex, _newFlow];

    GVAR(TransfusionMenu_Target) setVariable [VAR_FLUIDBAG_FLOW_IO, _flowArray, true];
};
