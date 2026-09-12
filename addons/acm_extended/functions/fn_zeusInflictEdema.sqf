// a zeus module: inflict pulmonary edema on the unit the module is dropped onto.
// it is modeled as fluid overload, ACM_circulation_Overload_Volume, in liters, because that is what it physically
// is: too much fluid in the circulation, backing up into the lungs.
// it is also how a medic causes it, by pouring crystalloid into someone who did not need it, so this module inflicts
// a real, reachable iatrogenic injury rather than an invented one.
// in the lung it shows up as recruitable shunt, in fn_ventoxygenation: flooded alveoli that are still connected to
// an airway, which is why PEEP treats it and oxygen alone does not.
// per the Module_F convention, _this is [_logic, _units, _activated], and the attached object is the target.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };

private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Pulmonary edema module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!alive _unit) exitWith {
    ["Pulmonary edema module: target must be alive.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

// 0.9 to 1.5 l of overload: enough to flood the lung and be worth treating, because a trivial edema is not a
// scenario.
private _liters = 0.9 + (random 0.6);
[_unit, _liters] remoteExec ["ACME_fnc_edemaSet", _unit];
[format ["Pulmonary edema inflicted (%1 L fluid overload).", _liters toFixed 1], 2] call ace_common_fnc_displayTextStructured;
call _cleanup;
