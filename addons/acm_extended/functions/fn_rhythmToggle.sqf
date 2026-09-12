/* Instructor/action induction. No destruction of native pain or native target vitals. */
params ["_medic", "_patient", "_code", "_label", "_targetHR", ["_epoch", -1]];
if (isNull _patient) exitWith {};
if (_epoch < 0) then {_epoch = [_patient] call ACME_fnc_clinicalEpoch;};
if (!local _patient) exitWith {[_patient, "rhythmToggle", [_medic, _patient, _code, _label, _targetHR, _epoch]] call ACME_fnc_ownerDispatch;};
if (!alive _patient || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {};
private _active = [_patient] call ACME_fnc_rhythmGet;
if (_patient getVariable ["ace_medical_inCardiacArrest", false]) exitWith {
    [_medic, "Patient is in cardiac arrest. Treat the arrest or use full heal; clearing a waveform cannot restore perfusion."] call ACME_fnc_clinicalNotice;
};
if (_active == _code) then {
    [_patient] call ACME_fnc_rhythmRelease;
    [_medic, format ["%1 cleared. Native rhythm restored.", _label]] call ACME_fnc_clinicalNotice;
} else {
    [_patient, "ACME_rhythm_targetHR", (_targetHR max 0)] call ACME_fnc_setVarNet;
    [_patient, _code, _epoch] call ACME_fnc_rhythmSet;
    [_medic, format ["%1 induced. Attach AED pads / open the LifePak to view.", _label]] call ACME_fnc_clinicalNotice;
};
