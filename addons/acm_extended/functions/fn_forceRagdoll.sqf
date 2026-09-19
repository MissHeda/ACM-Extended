// force a fresh ragdoll on an already-down, or any local, unit.
// an unconscious ACE patient is held in a locked switchmove pose rather than a live ragdoll, and re-asserting
// setunconscious true on a unit that is already unconscious is a no-op, giving no new ragdoll. to get a visible
// flop we toggle the engine unconscious flag off this frame and back on the next, which re-enters the ragdoll
// transition. ACE keeps the medical unconscious state, so the unit stays down throughout.
// that off frame does render, and it used to show. for one frame the engine sees a conscious unit, and a conscious
// unit with pain on board plays the pain expression, so a casualty who was seizing flashed a look of severe pain
// and then went blank again. it was reported as a glitch and it was one.
// so the pain is masked across the toggle and put back with the flag. the patient is unconscious the whole time as
// far as the medical sim is concerned, and nothing else reads pain in that single frame.
// call it as [_patient] call ACME_fnc_forceRagdoll.
params ["_patient"];
if (isNull _patient || {!alive _patient} || {!local _patient}) exitWith {};
// never force a ragdoll on a unit inside a vehicle: toggling unconscious re-enters the ragdoll transition and breaks
// or pops the seat animation. leave a mounted casualty in their seat.
if (!isNull objectParent _patient) exitWith {};

private _wasMedicalUncon = _patient getVariable ["ACE_isUnconscious", false];
private _pain = _patient getVariable ["ace_medical_pain", 0];
if (_pain > 0) then { [_patient, [["pain", 0, true]]] call ACM_core_fnc_setAceMedicalState; };

private _epoch = [_patient] call ACME_fnc_clinicalEpoch;
private _dragSession = _patient getVariable ["ACME_dragHandle_session", ""];
_patient setUnconscious false;
// ACM_LyingState and fixed unconscious poses may have no outgoing interpolation.
// Leave that locked state explicitly while still prone before requesting a fresh collapse.
["ace_common_switchMove", [_patient, "AmovPpneMstpSnonWnonDnon"]] call CBA_fnc_globalEvent;
[{
    params ["_p", "_pain", "_epoch", "_dragSession", "_wasMedicalUncon"];
    if (isNull _p || {!local _p} || {!alive _p}) exitWith {};
    if (_epoch != ([_p] call ACME_fnc_clinicalEpoch)) exitWith {};
    // A stop, wake-up or vehicle entry can happen between the two frames.
    if (!isNull objectParent _p
        || {_wasMedicalUncon && {!(_p getVariable ["ACE_isUnconscious", false])}}
        || {_dragSession != "" && {(_p getVariable ["ACME_dragHandle_session", ""]) != _dragSession}}) exitWith {
        if (_pain > 0 && {(_p getVariable ["ace_medical_pain", 0]) <= 0}) then {
            [_p, [["pain", _pain, true]]] call ACM_core_fnc_setAceMedicalState;
        };
    };
    _p setUnconscious true;
    // put the pain back, and only if nothing else claimed it while we were holding it at zero. a tick that raised
    // pain during this frame owns the value, so restoring our stale copy over the top would undo real damage.
    if (_pain > 0 && {(_p getVariable ["ace_medical_pain", 0]) <= 0}) then {
        [_p, [["pain", _pain, true]]] call ACM_core_fnc_setAceMedicalState;
    };
}, [_patient, _pain, _epoch, _dragSession, _wasMedicalUncon]] call CBA_fnc_execNextFrame;
