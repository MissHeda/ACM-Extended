// the raw sugammadex dose on board, iv, summed with im if a vial is ever pushed that way. it is the cumulative dose,
// so ACE decays it over the timeInSystem of the drug.
// call it as [_patient] call ACME_fnc_sugammadexOnBoard, which returns a number.
params ["_patient"];
if (isNull _patient || {isNil "ace_medical_status_fnc_getMedicationCount"}) exitWith {0};
private _rIV = [_patient, "Sugammadex_IV", false] call ace_medical_status_fnc_getMedicationCount;
private _rIM = [_patient, "Sugammadex", false] call ace_medical_status_fnc_getMedicationCount;
private _iv = if (_rIV isEqualType []) then { _rIV param [0, 0] } else { _rIV };
private _im = if (_rIM isEqualType []) then { _rIM param [0, 0] } else { _rIM };
_iv + _im
