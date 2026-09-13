/* Owner-local Zone 3 posture watcher. No network traffic is emitted during the loop. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {[_patient, "register", []] call ACME_fnc_ownerDispatch;};
if (!(_patient getVariable ["ACME_AAJT_zone3", false])) exitWith {};
if ((_patient getVariable ["ACME_AAJT_downedPFH", -1]) >= 0) exitWith {};
_patient setVariable ["ACME_AAJT_downedActive", true, false];
_patient setVariable ["ACME_AAJT_uprightSince", -1, false];
private _handle = [{
    params ["_args", "_h"];
    _args params ["_patient", "_owner", "_epoch"];
    private _same = (_patient getVariable ["ACME_AAJT_downedPFH", -1]) == _h;
    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_same}
        || {!alive _patient} || {!(_patient getVariable ["ACME_AAJT_zone3", false])}) exitWith {
        if (_same) then {[_patient] call ACME_fnc_aajtDownedStop;} else {[_h] call CBA_fnc_removePerFrameHandler;};
    };

    // AAJT-S never authors ACM's wake/lying state. If ACM has put a previously unconscious casualty into its
    // native lying state, leave that state completely alone until the casualty (or another provider) actually uses
    // ACM's Get Up path. Only then can a genuine STAND/CROUCH attempt start the delayed Zone 3 collapse timer.
    private _nativeLying = _patient getVariable ["ACM_core_Lying_State", false];
    private _uncon = (_patient getVariable ["ACE_isUnconscious", false]) || {_patient getVariable ["ace_medical_unconscious", false]};
    if (_uncon || {_nativeLying} || {_patient getVariable ["ACME_obtunded", false]}
        || {!isNull objectParent _patient} || {!isNull attachedTo _patient}) exitWith {
        _patient setVariable ["ACME_AAJT_uprightSince", -1, false];
    };

    // Do not interpret a treatment animation or an open self medical menu as an attempt to weight-bear. Treatment
    // events publish the grace timestamp from the provider's machine so remote providers are covered too.
    private _treatmentGrace = CBA_missionTime < (_patient getVariable ["ACME_AAJT_treatmentGraceUntil", -1]);
    private _selfMenu = hasInterface && {!isNil "ACE_player"} && {_patient isEqualTo ACE_player}
        && {!isNull (uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull])};
    private _poseOwned = (_patient getVariable ["ACME_treatmentPoseState", []]) isNotEqualTo []
        || {_patient getVariable ["ACME_animQActive", false]}
        || {_patient getVariable ["ACME_rollProviderActive", false]};
    if (_treatmentGrace || {_selfMenu} || {_poseOwned}) exitWith {_patient setVariable ["ACME_AAJT_uprightSince", -1, false];};

    private _upright = (toLowerANSI (stance _patient)) in ["stand", "crouch"];
    if (!_upright) exitWith {_patient setVariable ["ACME_AAJT_uprightSince", -1, false];};

    private _since = _patient getVariable ["ACME_AAJT_uprightSince", -1];
    if (_since < 0) exitWith {_patient setVariable ["ACME_AAJT_uprightSince", CBA_missionTime, false];};
    private _grace = missionNamespace getVariable ["ACME_aajt_uprightGrace", 1.45];
    if ((CBA_missionTime - _since) >= _grace) then {
        _patient setVariable ["ACME_AAJT_uprightSince", -1, false];
        [_patient] call ACME_fnc_aajtForceProne;
    };
}, 0.20, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_AAJT_downedPFH", _handle, false];
