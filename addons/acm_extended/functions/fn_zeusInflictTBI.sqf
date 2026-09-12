// a zeus module entry: open the TBI setup dialog for the targeted unit. per Module_F, _this is [_logic, ...].
// the dialog, ACME_TBIModule_Dialog, lets the game master pick a severity and an initial state, then applies it
// through ACME_fnc_tbiInit on confirm.
// it runs on the machine of the placing curator, because the dialog is client ui, and the actual state write is
// routed to the owner of the unit from the confirm handler.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };
private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["TBI module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!alive _unit) exitWith {
    ["TBI module: target must be alive.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

// stash the target for the dialog, and delete the logic now, because the dialog owns the interaction from here.
uiNamespace setVariable ["ACME_TBIModule_target", _unit];
call _cleanup;

[{ createDialog "ACME_TBIModule_Dialog"; }, [], 0.05] call CBA_fnc_waitAndExecute;
