/* NA4: owner/episode-bound AAJT posture enforcement. Clinical obtundation,
   weapon use and respiratory state are not changed by the aortic device. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {[_patient, "register", []] call ACME_fnc_ownerDispatch;};
if (!(_patient getVariable ["ACME_AAJT_inguinal", false])) exitWith {};
if (_patient getVariable ["ACME_AAJT_downedPFH", -1] >= 0) exitWith {};
_patient setVariable ["ACME_AAJT_downedActive", true, false];
private _handle = [{
    params ["_args", "_h"];
    _args params ["_patient", "_owner", "_epoch"];
    private _same = (_patient getVariable ["ACME_AAJT_downedPFH", -1]) == _h;
    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_same}
        || {!alive _patient} || {!(_patient getVariable ["ACME_AAJT_inguinal", false])}) exitWith {
        if (_same) then {[_patient] call ACME_fnc_aajtDownedStop;} else {[_h] call CBA_fnc_removePerFrameHandler;};
    };
    private _obtunded = _patient getVariable ["ACME_obtunded", false];
    private _busy = _obtunded || {_patient getVariable ["ACE_isUnconscious", false]}
        || {!isNull objectParent _patient} || {!isNull attachedTo _patient}
        || {_patient getVariable ["ACME_obtunded_transitioning", false]};
    if (_busy) exitWith {
        if (_patient getVariable ["ACME_AAJT_lockOn", false]) then {
            _patient setVariable ["ACME_AAJT_lockOn", false, false];
            if (!_obtunded && {hasInterface} && {_patient isEqualTo ACE_player}) then {
                [_patient, false] call ACME_fnc_obtundedInputLock;
            };
        };
    };
    if (hasInterface && {_patient isEqualTo ACE_player}) then {
        _patient setVariable ["ACME_AAJT_lockOn", true, false];
        // Rebuild only missing handlers. Another medical state may have released
        // the shared display handlers since the preceding tick.
        [_patient, true] call ACME_fnc_obtundedInputLock;
    };
    if ((toLower (stance _patient)) in ["stand", "crouch"]) then {
        private _last = _patient getVariable ["ACME_AAJT_downedAt", -1];
        if (_last < 0 || {time - _last > 2.5}) then {
            _patient setVariable ["ACME_AAJT_downedAt", time, false];
            _patient setUnitPos "AUTO";
            if (!isNil "ace_medical_engine_fnc_setUnconsciousAnim") then {
                _patient setVariable ["ACME_AAJT_collapseOwned", true, false];
                [_patient, true] call ace_medical_engine_fnc_setUnconsciousAnim;
                [{
                    params ["_patient", "_owner", "_epoch", "_worker"];
                    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
                        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}
                        || {(_patient getVariable ["ACME_AAJT_downedPFH", -1]) != _worker}
                        || {!alive _patient} || {!(_patient getVariable ["ACME_AAJT_inguinal", false])}) exitWith {};
                    if (_patient getVariable ["ACE_isUnconscious", false] || {_patient getVariable ["ACME_obtunded", false]}
                        || {!isNull attachedTo _patient} || {!isNull objectParent _patient}) exitWith {
                        _patient setVariable ["ACME_AAJT_collapseOwned", false, false];
                    };
                    [_patient, false] call ace_medical_engine_fnc_setUnconsciousAnim;
                    _patient setVariable ["ACME_AAJT_collapseOwned", false, false];
                    _patient setUnitPos "DOWN";
                }, [_patient, _owner, _epoch, _h], missionNamespace getVariable ["ACME_aajt_collapseTime", 1.6]] call CBA_fnc_waitAndExecute;
            };
            if (hasInterface && {_patient isEqualTo ACE_player}) then {
                ["Your legs are clamped off. You cannot stand.", 2, _patient] call ace_common_fnc_displayTextStructured;
            };
        };
    };
}, 0.25, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_AAJT_downedPFH", _handle, false];
