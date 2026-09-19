// Advance the visible seizure to the next BI spasm gesture. Each gesture is allowed to finish normally;
// fn_seizureMotion's GestureDone handler calls this again only after the current ACME seizure gesture completes.
// The four chosen BI gestures are aliased in config.cpp with speed = 1.35, so this does not touch global
// animation speed or alter the same gestures when another system/mod uses them.
params ["_patient"];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
if !(_patient getVariable ["ACME_seizure_motionActive", false]) exitWith {};
if !(missionNamespace getVariable ["ACME_seizure_animEnabled", true]) exitWith {};

// Do not fight seat, drag or carry animation ownership. The seizure physiology continues normally and the
// gesture driver retries once the patient has a free animation layer again.
if (!isNull objectParent _patient || {!isAwake _patient}
    || {_patient getVariable ["ACME_dragHandle_active", false]}
    || {_patient call ace_common_fnc_isBeingDragged}
    || {_patient call ace_common_fnc_isBeingCarried}) exitWith {
    if !(_patient getVariable ["ACME_seizure_motionRetryPending", false]) then {
        _patient setVariable ["ACME_seizure_motionRetryPending", true];
        [{
            params ["_p"];
            if (!isNull _p) then {
                _p setVariable ["ACME_seizure_motionRetryPending", false];
                if (_p getVariable ["ACME_seizure_motionActive", false]) then {
                    [_p] call ACME_fnc_seizureGestureAdvance;
                };
            };
        }, [_patient], 0.35] call CBA_fnc_waitAndExecute;
    };
};

private _gestures = [
    "ACME_SeizureSpasm3",
    "ACME_SeizureSpasm4",
    "ACME_SeizureSpasm5",
    "ACME_SeizureSpasm6"
];

// Randomize the order but do not immediately repeat the same spasm. This keeps long seizures from looking like
// a four-frame scripted loop while still using only the four variants selected for ACME.
private _last = _patient getVariable ["ACME_seizure_motionCurrentGesture", ""];
private _pool = _gestures - [_last];
if (_pool isEqualTo []) then {_pool = +_gestures;};
private _next = selectRandom _pool;

_patient setVariable ["ACME_seizure_motionAdvancePending", false];
_patient setVariable ["ACME_seizure_motionCurrentGesture", _next];
_patient playActionNow _next;
true
