// Compile-time override of ACM_core_fnc_getUp.
// B49: obtundation no longer prevents Get Up. If an obtunded casualty is physically down, the same ACM/vanilla
// UnconsciousOutProne recovery movement is used, but its animation speed is reduced so standing is visibly slow.
// The state itself never forces the player prone/supine and never auto-stands them.
params ["_patient", ["_authorized", true, [false]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACM_core_getUpRequest", [_patient, _authorized], _patient] call CBA_fnc_targetEvent;
};

// An inguinal AAJT-S still mechanically prevents weight bearing.
if (_patient getVariable ["ACME_AAJT_inguinal", false]) exitWith {
    if (_patient == ACE_player) then {
        ["Your legs are clamped off by the AAJT-S.", 2, _patient] call ace_common_fnc_displayTextStructured;
    };
};

// Head elevation must be released before a stand-up. Re-enter after the release animation settles.
if (_patient getVariable ["ACME_headElevated", false]) exitWith {
    [objNull, _patient] call ACME_fnc_headElevateStop;
    [{
        params ["_p"];
        if (isNull _p || {!alive _p} || {_p getVariable ["ACME_headElevated", false]}) exitWith {};
        _p setUnitPos "AUTO";
        [_p, true] call ACM_core_fnc_getUp;
    }, [_patient], (missionNamespace getVariable ["ACME_headElev_releaseAnimTime", 0.8]) + 0.35] call CBA_fnc_waitAndExecute;
};

private _wasLying = _patient getVariable ["ACM_core_Lying_State", false];
private _obtunded = _patient getVariable ["ACME_obtunded", false]
    && {!(_patient getVariable ["ACE_isUnconscious", false])};
if (!_authorized) exitWith {};

private _releaseAnims = [
    "ainjppnemstpsnonwrfldnon",
    "acm_lyingstate",
    toLower (missionNamespace getVariable ["ACME_obtunded_fixedAnim", "ACME_ObtundedBack"]),
    toLower (missionNamespace getVariable ["ACME_obtunded_rollToBackAnim", "AinjPpneMstpSnonWrflDnon_rolltoback"])
];
private _as = toLower animationState _patient;
// A free-posture obtunded casualty may be down in a perfectly valid vanilla/ACE prone or incapacitated-family
// state that is not in ACM's two stock names. Their previous lying flag is the strongest indication that Get Up is
// intentional, with prone/incapacitated as defensive fallbacks for debug and wake paths.
private _canRelease = _wasLying
    || {_as in _releaseAnims}
    || {_obtunded && {(stance _patient == "PRONE") || {lifeState _patient == "INCAPACITATED"}}};
if (!_canRelease) exitWith {};

// Do not consume the action until a valid release transaction has actually been accepted. Clearing this before
// the animation gate was the stuck-on-floor bug when obtundation was disabled.
_patient setVariable ["ACM_core_Lying_State", false, true];

private _roll = missionNamespace getVariable ["ACME_getUp_anim", "UnconsciousOutProne"];
private _nativeTime = missionNamespace getVariable ["ACME_getUp_animTime", 1.6];
private _rollPrio = missionNamespace getVariable ["ACME_getUp_priority", 1];
private _runTime = _nativeTime;

if (_obtunded) then {
    _runTime = (missionNamespace getVariable ["ACME_obtunded_getUpTime", 5.5]) max _nativeTime;
    // Slow the authored movement itself rather than just delaying the result. The coefficient is restored after the
    // exact obtunded get-up window and also on obtundation cleanup as a backstop.
    private _coef = (_nativeTime / _runTime) max 0.18 min 0.45;
    _patient setVariable ["ACME_obtunded_slowGetUp", true, false];
    _patient setAnimSpeedCoef _coef;
    [{
        params ["_p"];
        if (isNull _p || {!local _p}) exitWith {};
        _p setAnimSpeedCoef 1;
        _p setVariable ["ACME_obtunded_slowGetUp", false, false];
    }, [_patient], _runTime + 0.05] call CBA_fnc_waitAndExecute;
};

[_patient, [[_roll, _runTime, _rollPrio]], "replace"] call ACME_fnc_animQueue;

// Backstop only if the move graph failed to leave a release state. It uses the same run time, so an obtunded stand
// is never snapped early while its intentionally slowed animation is still playing.
[{
    params ["_p", "_roll", "_release"];
    if (isNull _p || {!alive _p}) exitWith {};
    if (_p getVariable ["ACM_core_Lying_State", false]) exitWith {};
    if (!((toLower animationState _p) in _release)) exitWith {};
    [_p, "", 0] call ACME_fnc_doAnimHeld;
    // B73: even the recovery backstop must use the move graph; never snap into Get Up with switchMove fallback.
    [_p, _roll, 1] call ACME_fnc_doAnim;
}, [_patient, _roll, _releaseAnims], _runTime + 0.4] call CBA_fnc_waitAndExecute;
