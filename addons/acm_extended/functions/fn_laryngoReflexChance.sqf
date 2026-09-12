/* B32: continuous, stimulus-dependent procedural gag response (game calibration).
   Sedation load is not RASS and ketamine dissociation is not reliable reflex abolition.
   Read only: no medication, unconsciousness, or native reflex state is rewritten. */
params ["_patient", ["_stimulation", 1, [0]]];
if (isNull _patient || {!alive _patient}
    || {_patient getVariable ["ace_medical_inCardiacArrest", false]}
    || {_patient getVariable ["ACME_roc_paralyzed", false]}) exitWith {0};
private _parts = [_patient] call ACME_fnc_sedationComponents;
_parts params ["_ket", "_prop", "_mid", "_fent", "_factor", "_load"];
// ACM's unconsciousness timer also clears the native reflex during ACME-owned drug
// sedation. Only that claimed state with current hypnotic exposure can retain a
// stimulus-dependent response. Other absent-reflex causes remain absent.
private _drugSuppressed = (_patient getVariable ["ACME_ket_sedated", false]) && {_load > 0};
if (!(_patient getVariable ["ACM_airway_AirwayReflex_State", false]) && {!_drugSuppressed}) exitWith {0};
if (!finite _stimulation) then {_stimulation = 1;};
_stimulation = _stimulation max 0 min 3;
// Relative procedural-reflex effects, not dose conversions or clinical thresholds.
private _suppression = ((_ket max 0) * 0.45 + (_prop max 0) + (_mid max 0) * 0.8)
    * (_factor max 1);
private _sensitivity = exp (-2.5 * _suppression);
(1 - exp (-2.3 * _sensitivity * _stimulation)) max 0 min 1
