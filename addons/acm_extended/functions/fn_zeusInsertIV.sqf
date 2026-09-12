// a zeus module entry: open the Place IV dialog for the targeted unit. per Module_F, _this is [_logic, ...].
// the dialog, ACME_IVModule_Dialog, lets the game master pick a limb, an access site and a gauge, and
// ACME_fnc_zeusIVDialogConfirm applies it.
// it runs on the machine of the placing curator, because the dialog is client ui. the state write is routed to
// the owner of the unit from the confirm handler.
// this is a copy of the shape fn_zeusInflictTBI uses, deliberately. the module entry points on this addon all
// resolve their target and clean up their logic the same way, and a second shape would be a second set of
// failure modes.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };
private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Place IV module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

// an IV goes into a dead casualty as readily as a live one, mechanically, and a game master setting up a scene
// has a reason to do it. the module does not check for life.

// stash the target for the dialog, and delete the logic now, because the dialog owns the interaction from here.
uiNamespace setVariable ["ACME_IVModule_target", _unit];
call _cleanup;

[{ createDialog "ACME_IVModule_Dialog"; }, [], 0.05] call CBA_fnc_waitAndExecute;
