// a zeus module entry: clear a traumatic brain injury, and all the ICP state, from the unit the module was dropped
// onto.
// per Module_F, _this is [_logic, ...], and the synced or attached object is the target.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };
private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Clear TBI module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

private _had = _unit getVariable ["ACME_tbi_HasTBI", false];

if (local _unit) then {
    [_unit] call ACME_fnc_zeusClearTBILocal;
} else {
    [_unit] remoteExec ["ACME_fnc_zeusClearTBILocal", _unit];
};

private _msg = if (_had) then { format ["TBI cleared on %1.", name _unit] } else { format ["%1 had no TBI.", name _unit] };
[_msg, 2] call ace_common_fnc_displayTextStructured;

call _cleanup;
