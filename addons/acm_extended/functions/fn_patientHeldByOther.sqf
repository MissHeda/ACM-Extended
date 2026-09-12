// is somebody else holding this casualty right now?
// call it as [_patient] call ACME_fnc_patientHeldByOther, which returns true if we must not move them.
// it covers being carried, dragged, loaded in a vehicle, or attached to anything that is not one of our own pose
// helpers. any of those means their position belongs to someone else, and forcing it produces the floating,
// sinking and teleporting that this addon has been blamed for.
params ["_patient"];
if (isNull _patient) exitWith { true };

if (!isNull objectParent _patient) exitWith { true };  // in a vehicle
if (_patient getVariable ["ace_dragging_isCarried", false]) exitWith { true };
if (_patient getVariable ["ace_dragging_isDragged", false]) exitWith { true };

private _to = attachedTo _patient;
if (isNull _to) exitWith { false };

// attached to one of ours is fine. attached to anything else is not ours to undo.
private _ours = [
    _patient getVariable ["ACME_headElev_helper", objNull],
    // fn_obtundedTick.sqf retires this legacy helper when the old pose is released.
    _patient getVariable ["ACME_obtunded_dirHolder", objNull]
];
!(_ours findIf { !isNull _x && {_to isEqualTo _x} } >= 0)
