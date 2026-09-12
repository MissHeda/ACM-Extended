/* B14: antiarrhythmic benefit follows current native drug effect, not a 90-minute latch. */
params ["_patient"];
if (isNull _patient || {isNil "ACM_circulation_fnc_getCardiacMedicationEffects"}) exitWith {0};
private _effects = [_patient] call ACM_circulation_fnc_getCardiacMedicationEffects;
private _effect = if (_effects isEqualType createHashMap) then {(_effects getOrDefault ["lidocaine",0]) max 0 min 1} else {0};
if (local _patient) then {[_patient,"ACME_rhythm_lidoEffectiveness",_effect] call ACME_fnc_setVarNet;};
_effect
