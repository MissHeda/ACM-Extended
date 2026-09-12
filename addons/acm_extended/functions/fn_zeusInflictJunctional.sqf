// a zeus module entry: inflict a junctional hemorrhage on the unit the module was dropped onto.
// it places a bleed on a random currently-uninjured limb, an arm or a leg. drop it again for another limb.
// per the Module_F convention, _this is [_logic, _units, _activated], and the synced or attached object is the
// target. it uses ACME_fnc_junctionalInflict, which is limbs only: leftarm, rightarm, leftleg and rightleg.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };

// clean up the placed logic regardless of the outcome.
private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Junctional module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!alive _unit) exitWith {
    ["Junctional module: target must be alive.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

// the inflict function is local-only, because it starts a local bleed pfh, so run it where the unit is local.
if (local _unit) then {
    [_unit] call ACME_fnc_zeusInflictJunctionalLocal;
} else {
    [_unit] remoteExec ["ACME_fnc_zeusInflictJunctionalLocal", _unit];
};

call _cleanup;
