private _acmeBinding = "NA3:getBloodPressure";
// NA3 authoritative ACE/ACM pressure endpoint. All measurement consumers use this symbol.
params ["_unit"];
[_unit, true, false] call ACME_fnc_bpCompute
