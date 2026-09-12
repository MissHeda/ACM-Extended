// Native-determinant pressure baseline; same formula, capillary key and tension ramp as the final endpoint.
// No Extended resistance additions or residual pressure-shape modifiers are included.
params ["_unit"];
[_unit, false, false] call ACME_fnc_bpCompute
