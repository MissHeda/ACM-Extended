#include "\x\ACM\addons\core\script_component.hpp"
/* B14: bounded additive medication effects consumed ONCE by the native vitals loop.
   Targets, not guaranteed displayed vital-sign changes. Native analgesia and ventilation remain.
   Shock reserve is an explicit GAME proxy, not a measured catecholamine concentration.
   No ICP increment, random arrest, or airway injury is triggered by this function. */
params ["_patient"];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {[0,0,0,0]};
private _c = [_patient] call ACME_fnc_sedationComponents;
private _ket = (_c select 0) max 0;
private _prop = (_c select 1) max 0;
private _mid = (_c select 2) max 0;
private _volume = GET_BLOOD_VOLUME(_patient);
private _state = _patient getVariable ["ACME_circ_State", createHashMap];
private _acid = (_state getOrDefault ["acidosis", 0]) max 0 min 1;
private _reserve = (linearConversion [2.5, 5.0, _volume, 0.05, 1, true]) * (1 - 0.6 * _acid);
private _symp = _ket / (0.55 + _ket);
private _depleted = linearConversion [0.4, 0.1, _reserve, 0, 1, true];
private _hr = 22 * _symp * _reserve - 5 * _symp * _depleted;
private _svr = 16 * _symp * _reserve - 12 * _symp * _depleted;
// Hypovolemia increases depressant susceptibility; no duplicate native RR/CO2 dose here.
_svr = _svr - (25 * (_prop / (0.7 + _prop)) + 8 * (_mid / (0.8 + _mid)))
    * (1 + 0.4 * (1 - _reserve));
// B38 replaces the old opioid-only interaction term, rather than stacking another
// penalty over it. All administration paths share the same admitted exposures.
private _interactions = [_patient, _c, _reserve] call ACME_fnc_medicationInteractions;
_hr = _hr + (_interactions select 0);
_svr = _svr + (_interactions select 1);
private _co2 = _interactions select 3;
private _rapid = _patient getVariable ["ACME_ketRapidLoad", 0];
private _ketDepression = (linearConversion [1.6, 3.2, _ket, 0, 0.3, true])
    + (linearConversion [0.8, 2.0, _rapid, 0, 0.15, true]);
_co2 = _co2 - (_ketDepression min 0.4);
private _rr = (_interactions select 2) - 4 * (_ketDepression min 0.4);
if (_patient getVariable ["ace_medical_inCardiacArrest", false]) then {_hr = 0;};
[_patient, "ACME_ket_sympatheticEffect", _symp * _reserve] call ACME_fnc_setVarNet;
[_patient, "ACME_sedation_hrAdjust", _hr] call ACME_fnc_setVarNet;
[_patient, "ACME_sedation_resistAdjust", _svr] call ACME_fnc_setVarNet;
[_hr, _svr, _rr, _co2]
