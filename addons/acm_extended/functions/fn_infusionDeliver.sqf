/* Input pending amount has already reached the patient. No history truncation and no instant drug conversion. */
params ["_patient", "_entry", ["_force", false]];
private _pending = _entry param [15, 0];
if (!local _patient || {_pending <= 0}) exitWith {_entry};
private _med = _entry param [11, ""];
private _min = ACME_infusion_minPulseDose getOrDefault [_med, 1];
if (!_force && {_pending < _min} && {(CBA_missionTime - (_entry param [16, 0])) < ACME_infusion_pulseInterval}) exitWith {_entry};
private _elapsed = (CBA_missionTime - (_entry param [16,CBA_missionTime])) max 0.25;
// Mark settled before the native callback: its handlers may inspect this same object synchronously.
_entry set [15, 0]; _entry set [16, CBA_missionTime];
private _previous = missionNamespace getVariable ["ACME_vesicant_infusionDelivery", false];
missionNamespace setVariable ["ACME_vesicant_infusionDelivery", true];
[_patient, _entry select 1, _entry select 12, _pending, true, true, [_entry select 4, [], _elapsed, "infusion"]] call ace_medical_treatment_fnc_medicationLocal;
missionNamespace setVariable ["ACME_vesicant_infusionDelivery", _previous];
_entry
