/* Native arrest transition on the patient owner. ACM's reversible-cause priority remains authoritative. */
params ["_patient", ["_rhythm", 5], ["_epoch", -1]];
if (isNull _patient) exitWith {};
if (_epoch < 0) then {_epoch = [_patient] call ACME_fnc_clinicalEpoch;};
if (!local _patient) exitWith {[_patient, "arrest", [_patient, _rhythm, _epoch]] call ACME_fnc_ownerDispatch;};
if (!alive _patient || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!(_rhythm in [1,2,3,5])}) exitWith {};
[_patient, _rhythm] call ACM_circulation_fnc_setCardiacArrestTargetRhythm;
_patient setVariable ["ACME_nativeRequestedRhythm", _rhythm, false];
if (_patient getVariable ["ace_medical_inCardiacArrest", false]) exitWith {
    [_patient] call ACM_circulation_fnc_updateCirculationState;
    if (_rhythm != 1 && {!(_patient getVariable ["ACM_circulation_CirculationState", true])}) then {_rhythm = 5;};
    [_patient, [["cardiacRhythmState", _rhythm]], true] call ACM_circulation_fnc_setRuntimeState;
    _patient setVariable ["ACME_nativeRequestedRhythm", nil, false];
};
if (([_patient] call ACME_fnc_rhythmNative) in [1,2,3,5]) then {[_patient, [["cardiacRhythmState", 0]], false] call ACM_circulation_fnc_setRuntimeState;};
// An early raw-asystole write would short-circuit ACM's onCardiacArrest initialization.
["ace_medical_FatalVitals", _patient] call CBA_fnc_localEvent;
_patient setVariable ["ACME_nativeRequestedRhythm", nil, false];
