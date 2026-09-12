// set the fluid overload of a patient directly, in liters. this is the one place pulmonary edema is written, so the
// zeus modules, the debug menu and anything else all go through the same door.
// call it as [_patient, _liters] call ACME_fnc_edemaSet.
params ["_patient", ["_liters", 0]];
if (isNull _patient) exitWith {};
_liters = (_liters max 0) min 6;
[_patient, [["overloadVolume", _liters]], true] call ACM_circulation_fnc_setRuntimeState;
// register into the circulation loop, so the lung actually feels it. the compliance and shunt are computed
// there.
if (_liters > 0 && {!isNil "ACME_circ_activePatients"}) then {
    ACME_circ_activePatients pushBackUnique _patient;
};
