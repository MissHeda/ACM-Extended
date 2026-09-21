// Network-visible seizure gesture presentation.
// The owner still owns physiology and sequencing. Each gesture transition is replayed on every interface client,
// while the owner machine also executes it so its GestureDone EH advances the authoritative sequence.
params [
    ["_patient", objNull, [objNull]],
    ["_session", [], [[]]],
    ["_gesture", "", [""]],
    ["_active", true, [false]]
];
if (isNull _patient) exitWith {false};

// Machines that neither render the casualty nor own it have no reason to touch the gesture layer.
if (!hasInterface && {!local _patient}) exitWith {false};

private _observerSession = _patient getVariable ["ACME_seizure_observerSession", []];

if (!_active) exitWith {
    if (_session isEqualTo [] || {_observerSession isEqualTo _session} || {local _patient}) then {
        if (((toLowerANSI (gestureState _patient)) find "acme_seizurespasm") == 0) then {
            _patient switchGesture "GestureEmpty";
        };
        _patient setVariable ["ACME_seizure_observerSession", [], false];
    };
    true
};

// Never render seizure body motion in a vehicle. Physiology remains active and the owner restarts visuals after exit.
if (!isNull objectParent _patient) exitWith {
    if (((toLowerANSI (gestureState _patient)) find "acme_seizurespasm") == 0) then {
        _patient switchGesture "GestureEmpty";
    };
    _patient setVariable ["ACME_seizure_observerSession", [], false];
    false
};

if (_session isEqualTo [] || {_gesture == ""}) exitWith {false};
_patient setVariable ["ACME_seizure_observerSession", +_session, false];
_patient switchGesture [_gesture, 0, 1, false];
true
