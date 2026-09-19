// Relative drag burden for the ACME drag handle.
// ACE's own dragging weight is based on loadAbs + object mass. We keep the same shape but do not honor ACE's
// optional "ignore weight" coefficient because the entire point of this system is that a loaded casualty feels heavy.
params [["_patient",objNull,[objNull]]];
if (isNull _patient) exitWith {350};

private _load = loadAbs _patient;
if !(_load isEqualType 0 && {finite _load}) then {_load = 0;};
private _mass = getMass _patient;
if !(_mass isEqualType 0 && {finite _mass}) then {_mass = 80;};

// Unitless but ACE-compatible relative burden. 350 is a lightly equipped casualty; heavy kit can climb well
// above 700. The upper clamp prevents pathological modded inventories from making the spring numerically unstable.
private _weight = ((_load + (_mass max 0)) * 0.5) max 350;
_weight min 1200
