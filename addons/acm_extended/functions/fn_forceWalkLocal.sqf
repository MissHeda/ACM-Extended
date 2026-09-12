/* Locality-safe forceWalk endpoint for patient-owner dispatch. */
params [
    ["_unit", objNull, [objNull]],
    ["_force", false, [true]]
];
if (isNull _unit || {!local _unit}) exitWith {};
_unit forceWalk _force;
