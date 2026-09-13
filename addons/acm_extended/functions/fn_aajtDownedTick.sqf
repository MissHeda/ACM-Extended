/* Owner-local Zone 3 posture watcher. No network traffic is emitted during the loop. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {[_patient, "register", []] call ACME_fnc_ownerDispatch;};
if (!(_patient getVariable ["ACME_AAJT_zone3", false])) exitWith {};
if ((_patient getVariable ["ACME_AAJT_downedPFH", -1]) >= 0) exitWith {};
_patient setVariable ["ACME_AAJT_downedActive", true, false];
private _handle = [{
    params ["_args", "_h"];
    _args params ["_patient", "_owner", "_epoch"];
    private _same = (_patient getVariable ["ACME_AAJT_downedPFH", -1]) == _h;
    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_same}
        || {!alive _patient} || {!(_patient getVariable ["ACME_AAJT_zone3", false])}) exitWith {
        if (_same) then {[_patient] call ACME_fnc_aajtDownedStop;} else {[_h] call CBA_fnc_removePerFrameHandler;};
    };
    if (_patient getVariable ["ACE_isUnconscious", false]
        || {_patient getVariable ["ACME_obtunded", false]}
        || {!isNull objectParent _patient} || {!isNull attachedTo _patient}) exitWith {};
    if ((toLowerANSI (stance _patient)) in ["stand", "crouch"]) then {[_patient] call ACME_fnc_aajtForceProne;};
}, 0.20, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_AAJT_downedPFH", _handle, false];
