// Provider-side owner for temporary chest-access carrier handling.
// Uses the exact medic4 body-handling state used by physical Flip, freezes at 2.2 s, and remains there
// until the casualty-side lift/remove/lower transaction explicitly releases it.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]],
    ["_op", "start", [""]],
    ["_handoff", false, [false]]
];
if (isNull _medic) exitWith {-1};
_op = toLowerANSI _op;

if (!local _medic) exitWith {
    [_medic, "chestAccessVestProvider", [_medic, _patient, _op, _handoff]] call ACME_fnc_ownerDispatch;
    -1
};

if (_op == "stop") exitWith {
    private _entry = _medic getVariable ["ACME_chestAccessProvider", []];
    private _entryPatient = _entry param [0, objNull];
    private _epoch = _entry param [1, -1];
    private _pose = _medic getVariable ["ACME_treatmentPoseState", []];

    if ((_entryPatient isEqualTo _patient)
        && {_epoch >= 0}
        && {(_pose param [0, -2]) == _epoch}
        && {(_pose param [1, ""]) == "chestAccess"}) then {
        [_medic, "chestAccess", _epoch, _handoff] call ACME_fnc_treatmentPoseStop;
    };

    if (_entryPatient isEqualTo _patient) then {
        _medic setVariable ["ACME_chestAccessProvider", [], false];
    };
    _epoch
};

if (!alive _medic
    || {_medic getVariable ["ACE_isUnconscious", false]}
    || {[_medic] call ACME_fnc_animBlocked}
    || {_medic isEqualTo _patient}) exitWith {-1};

private _entry = _medic getVariable ["ACME_chestAccessProvider", []];
private _existingPatient = _entry param [0, objNull];
private _existingEpoch = _entry param [1, -1];
private _pose = _medic getVariable ["ACME_treatmentPoseState", []];
if ((_existingPatient isEqualTo _patient)
    && {_existingEpoch >= 0}
    && {(_pose param [0, -2]) == _existingEpoch}
    && {(_pose param [1, ""]) == "chestAccess"}) exitWith {_existingEpoch};

private _epoch = [_medic, "chestAccess", -1, _patient] call ACME_fnc_treatmentPoseStart;
if (_epoch >= 0) then {
    _medic setVariable ["ACME_chestAccessProvider", [_patient, _epoch], false];
};
_epoch
