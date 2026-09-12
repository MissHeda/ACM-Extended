// Turn the physics collision of a casualty off while a positioning animation plays, and turn it on again after.
// Call it as [_patient, false] call ACME_fnc_headElevCollision to turn collision off, and [_patient, true] to
// turn it on.
//
// WHY IT EXISTS.
// A casualty keeps a PhysX mass while an animation moves their body. A provider who stands inside that body is
// pushed by it, and the push can be hard enough to throw the provider and kill them.
// ACE has the same problem while it drags a casualty, and it solves it by setting the mass to almost zero, see
// ace_dragging fnc_startDragLocal. This uses the same method and the same ACE event, so the mass is the same on
// every machine.
//
// The original mass is kept in ACME_headElev_mass, which the teardown paths already read and restore.
params [["_patient", objNull, [objNull]], ["_enabled", true, [true]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevCollision", [_patient, _enabled]] call ACME_fnc_ownerDispatch;};

if (_enabled) exitWith {
    private _mass = _patient getVariable ["ACME_headElev_mass", -1];
    if (!(_mass isEqualType 0) || {_mass <= 0}) exitWith {};
    ["ace_common_setMass", [_patient, _mass]] call CBA_fnc_globalEvent;
    _patient setVariable ["ACME_headElev_mass", nil, true];
};

// A second request must not record the almost-zero mass as the original.
if ((_patient getVariable ["ACME_headElev_mass", -1]) > 0) exitWith {};
private _mass = getMass _patient;
if (_mass <= 1) exitWith {};  // already weightless, so there is nothing to turn off
_patient setVariable ["ACME_headElev_mass", _mass, true];
["ace_common_setMass", [_patient, 1e-12]] call CBA_fnc_globalEvent;
