#include "..\script_component.hpp"
/* B13: actual CaCl2-equivalent mg. The first-gram bonus is dose-conserving across pulses. */
private _acmeBinding = "B13:handleMed_CalciumChlorideLocal";
params ["_patient", "", "", ["_dose", 0]];
if (isNull _patient || {!local _patient} || {!alive _patient} || {!(_dose isEqualType 0)} || {!finite _dose} || {_dose <= 0}) exitWith {};
private _grams = _dose / 1000;
private _first = _patient getVariable ["ACME_nativeCalciumFirstGram", if (_patient getVariable [QGVAR(Calcium_FirstDose), false]) then {1} else {0}];
private _bonusGrams = _grams min ((1 - _first) max 0);
_patient setVariable ["ACME_nativeCalciumFirstGram", (_first + _bonusGrams) min 1, true];
_patient setVariable [QGVAR(Calcium_FirstDose), (_first + _bonusGrams) >= 1, true];
private _given = 2 * _grams + 0.5 * _bonusGrams;
_patient setVariable [QGVAR(Calcium_Count), (_patient getVariable [QGVAR(Calcium_Count), 0]) + _given, true];
