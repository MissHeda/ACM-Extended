/* Local, low-frequency severe-pain floor while any AAJT-S is on an awake casualty. Analgesia remains effective
   because ACE pain suppression is separate from raw pain. No network variable is written by this worker. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {[_patient, "register", []] call ACME_fnc_ownerDispatch;};
private _any = (_patient getVariable ["ACME_AAJT_zone3", false])
    || {_patient getVariable ["ACME_AAJT_inguinal", false]}
    || {_patient getVariable ["ACME_AAJT_axillaleft", false]}
    || {_patient getVariable ["ACME_AAJT_axillaright", false]};
if (!_any) exitWith {};
if ((_patient getVariable ["ACME_AAJT_painPFH", -1]) >= 0) exitWith {};
private _handle = [{
    params ["_args", "_h"];
    _args params ["_patient", "_owner", "_epoch"];
    private _same = (_patient getVariable ["ACME_AAJT_painPFH", -1]) == _h;
    private _any = !isNull _patient && {
        (_patient getVariable ["ACME_AAJT_zone3", false])
        || {_patient getVariable ["ACME_AAJT_inguinal", false]}
        || {_patient getVariable ["ACME_AAJT_axillaleft", false]}
        || {_patient getVariable ["ACME_AAJT_axillaright", false]}
    };
    if (isNull _patient || {!local _patient} || {clientOwner != _owner}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_same} || {!alive _patient} || {!_any}) exitWith {
        if (_same) then {_patient setVariable ["ACME_AAJT_painPFH", -1, false];};
        [_h] call CBA_fnc_removePerFrameHandler;
    };
    private _zone3 = _patient getVariable ["ACME_AAJT_zone3", false];
    // Zone 3 maintains a raw severe-pain floor even while unconscious so analgesia/decay cannot erase the
    // underlying device pain. Other AAJT placements retain the previous awake-only behavior.
    if (!_zone3 && {_patient getVariable ["ACE_isUnconscious", false]}) exitWith {};
    private _target = if (_zone3) then {missionNamespace getVariable ["ACME_aajt_zone3PainFloor", 0.95]} else {missionNamespace getVariable ["ACME_aajt_severePainFloor", 0.82]};
    private _cur = _patient getVariable ["ace_medical_pain", 0];
    if (_cur < _target) then {[_patient, _target - _cur] call ace_medical_fnc_adjustPainLevel;};
}, 1.0, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_AAJT_painPFH", _handle, false];
