// Visible generalized-seizure motion.
//
// ACME previously synthesized convulsions by changing the patient's heading every frame and periodically forcing
// extra ragdolls. That produced the fine "jitter", body slewing and sliding that this system is replacing.
//
// The seizure visual now uses BI's GestureSpasm3, 4, 5 and 6 through ACME-specific CfgGestures aliases. Those
// aliases play at 1.35x speed and preserve BI's original RTM/mask data. GestureDone advances the sequence, so
// every individual spasm completes before another begins. The variants are randomized without immediate repeats.
//
// This function owns VISUALS only. Loss of consciousness, apnea, HR response, postictal state and treatment are
// still owned by the seizure physiology state machine. Call as [_patient, true/false] call ACME_fnc_seizureMotion.
params ["_patient", ["_on", true]];
if (isNull _patient || {!local _patient}) exitWith {};

// Retire the old per-frame heading/ragdoll driver if a casualty was already seizing across a hot reload/update.
private _legacyPFH = _patient getVariable ["ACME_seizure_motionPFH", -1];
if (_legacyPFH isEqualType 0 && {_legacyPFH >= 0}) then {
    _legacyPFH call CBA_fnc_removePerFrameHandler;
    _patient setVariable ["ACME_seizure_motionPFH", -1];
    if (alive _patient) then {
        _patient setDir (_patient getVariable ["ACME_seizure_motionBaseDir", getDir _patient]);
    };
};

private _visualEnabled =
    _on
    && {alive _patient}
    && {missionNamespace getVariable ["ACME_seizure_animEnabled", true]}
    && {(missionNamespace getVariable ["ACME_seizure_motionEnabled", 1]) != 0};

if (!_visualEnabled) exitWith {
    _patient setVariable ["ACME_seizure_motionActive", false];
    _patient setVariable ["ACME_seizure_motionRetryPending", false];

    private _eh = _patient getVariable ["ACME_seizure_motionGestureEH", -1];
    if (_eh isEqualType 0 && {_eh >= 0}) then {
        _patient removeEventHandler ["GestureDone", _eh];
    };
    _patient setVariable ["ACME_seizure_motionGestureEH", -1];
    _patient setVariable ["ACME_seizure_motionCurrentGesture", ""];
};

// Idempotent: the physiology tick may call this every update while the seizure is active.
if (_patient getVariable ["ACME_seizure_motionActive", false]) exitWith {};

_patient setVariable ["ACME_seizure_motionActive", true];
_patient setVariable ["ACME_seizure_motionRetryPending", false];
_patient setVariable ["ACME_seizure_motionCurrentGesture", ""];

// Remove a stale event handler before installing the single owner for this seizure episode.
private _oldEH = _patient getVariable ["ACME_seizure_motionGestureEH", -1];
if (_oldEH isEqualType 0 && {_oldEH >= 0}) then {
    _patient removeEventHandler ["GestureDone", _oldEH];
};

private _eh = _patient addEventHandler ["GestureDone", {
    params ["_unit", "_gesture"];

    if !(_unit getVariable ["ACME_seizure_motionActive", false]) exitWith {};

    // Do not let an unrelated hand signal/reload gesture advance the seizure sequence.
    private _current = _unit getVariable ["ACME_seizure_motionCurrentGesture", ""];
    if (_current == "") exitWith {};
    if ((toLowerANSI _gesture) find (toLowerANSI _current) < 0) exitWith {};

    // Leave the completed gesture's final frame cleanly, then begin the next one on the next scheduler frame.
    [{
        params ["_p"];
        if (!isNull _p && {_p getVariable ["ACME_seizure_motionActive", false]}) then {
            [_p] call ACME_fnc_seizureGestureAdvance;
        };
    }, [_unit]] call CBA_fnc_execNextFrame;
}];
_patient setVariable ["ACME_seizure_motionGestureEH", _eh];

// Keep the existing onset collapse readable before the first spasm. This is the only seizure timing gap; once
// gestures start, GestureDone chains them continuously with no arbitrary sleep between variants.
private _settle = (missionNamespace getVariable ["ACME_seizure_settleDur", 1.5]) max 0;
[{
    params ["_p"];
    if (!isNull _p && {_p getVariable ["ACME_seizure_motionActive", false]}) then {
        [_p] call ACME_fnc_seizureGestureAdvance;
    };
}, [_patient], _settle] call CBA_fnc_waitAndExecute;

true
