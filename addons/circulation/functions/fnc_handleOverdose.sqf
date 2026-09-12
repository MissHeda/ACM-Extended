/* B13:handleOverdose. Owner tick replaces unmanaged one-hour wait callbacks.
   Repeated infusion pulses update one request; they cannot stack duplicate toxicity workers. */
private _acmeBinding = "B13:handleOverdose";
params ["_patient", "_classname", "_maxDose", "_doseDeviation", "_doseConcentration", "_maxEffectDose"];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
private _supported = ["Amiodarone_IV","Ketamine","Ketamine_IV","Lidocaine","Fentanyl","Fentanyl_IV","Fentanyl_BUC","Morphine","Morphine_IV","Penthrox"];
if !(_classname in _supported) exitWith {};
private _pending = _patient getVariable ["ACME_medicationToxicity", []];
if ((_pending findIf {(_x select 0) == _classname}) < 0) then {
    _pending pushBack [_classname, _maxDose + _doseDeviation, _maxEffectDose];
    _patient setVariable ["ACME_medicationToxicity", _pending, true];
};
[_patient] call ACME_fnc_ownerRegister;
