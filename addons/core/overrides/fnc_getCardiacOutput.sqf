#include "..\script_component.hpp"
/*
 * Fork-native ACE cardiac output with the ACM Extended true-PEA rule.
 * Organized electrical activity in true PEA has no mechanical cardiac output.
 */

#define VENTRICLE_STROKE_VOL 95e-3

params ["_unit"];
if (isNull _unit) exitWith {0};
if ((_unit getVariable ["ace_medical_inCardiacArrest", false]) && {([_unit] call ACME_fnc_rhythmGet) == 5}) exitWith {0};

private _bloodVolumeRatio = GET_BLOOD_VOLUME(_unit) / DEFAULT_BLOOD_VOLUME;
private _heartRate = GET_HEART_RATE(_unit);
private _entering = linearConversion [0.5, 1, _bloodVolumeRatio, 0, 1, true];
private _cardiacOutput = (_entering * VENTRICLE_STROKE_VOL) * _heartRate / 60;

0 max _cardiacOutput
