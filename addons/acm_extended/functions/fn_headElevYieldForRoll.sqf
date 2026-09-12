// our pose comes first, and it lets go properly.
// call it as [_patient] call ACME_fnc_headElevYieldForRoll, which returns true if it had to release and false if
// there was nothing to do.
// anything that rolls a casualty is incompatible with somebody holding their head up. playing a roll on top of an
// elevated head is two systems fighting over the same body, and ours loses silently and leaves the pose stuck. so
// before any roll, the head goes down first, deliberately, with the release animation, and the elevation is torn
// down properly rather than being overwritten.
// call this before playing any roll on a casualty. it is cheap and it is a no-op on anyone whose head is not up.
params ["_patient"];
if (isNull _patient) exitWith { false };
if (!(_patient getVariable ["ACME_headElevated", false])) exitWith { false };

// the release is the medic setting the head down, and fn_headelevatestop queues it along with the settled
// pose. it used to be played here as well, so the casualty got two of them and the second cut the first off
// partway. the roll that follows this call queues behind both, so it plays after the head is down.
// the stop takes [_medic, _patient]. this passed one argument, which put the casualty in the medic slot and
// left the patient null, so the stop exited on its first line and this teardown never happened at all.
[objNull, _patient] call ACME_fnc_headElevateStop;
true
