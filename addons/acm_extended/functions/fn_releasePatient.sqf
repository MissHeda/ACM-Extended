// let go of a casualty without stealing them from someone else.
// call it as [_patient, _ourHelper] call ACME_fnc_releasePatient, which returns true if we released and false if we
// left them alone.
// this is the HPMK flying bug. our pose systems attach the casualty to a helper object to hold them in a position,
// and their teardown then called a bare detach _patient. that is fine when we are the only thing holding them,
// and it is not fine at all otherwise, because ACE's drag and carry also attach the casualty, to the medic.
// every one of our teardowns is deferred through waitandexecute, so there is a window of a few tenths of a second
// between deciding to let go and actually doing it. pick the casualty up inside that window and our timer fires
// afterwards and detaches them from the medic. ACE still believes it is carrying them and keeps driving the
// carry, while the casualty is no longer attached to anything. that is the flying.
// the recovery position, an HPMK wrap and a carry in quick succession is simply the easiest way to land inside that
// window, which is why that specific sequence reproduces it every time.
// so: only ever detach a casualty from our own helper. if they are attached to anything else, that is somebody
// else's business and we leave it alone.
params ["_patient", ["_helper", objNull]];
if (isNull _patient) exitWith { false };

private _to = attachedTo _patient;
if (isNull _to) exitWith { false };  // not attached to anything, so there is nothing to release.
if (!isNull _helper && {_to isEqualTo _helper}) exitWith { detach _patient; true };
if (isNull _helper) exitWith { false };  // there is no helper to compare against, so do not guess.
false
