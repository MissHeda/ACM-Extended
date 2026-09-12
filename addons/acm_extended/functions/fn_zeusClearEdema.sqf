// a zeus module: clear pulmonary edema, draining the fluid overload, from the unit the module is dropped onto.
// it is the counterpart to inflict pulmonary edema. instructors need to be able to take an injury back off rather
// than only put it on, or you cannot run the same casualty twice.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };

private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Clear edema module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

[_unit, 0] remoteExec ["ACME_fnc_edemaSet", _unit];
["Pulmonary edema cleared.", 2] call ace_common_fnc_displayTextStructured;
call _cleanup;
