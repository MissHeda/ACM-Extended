// read the mean arterial pressure of the patient from ACE and ACM.
// MAP is about the diastolic plus (systolic minus diastolic) over 3.
// it falls back to a sane default if the bp function is unavailable.
params ["_patient"];
if (isNull _patient) exitWith {missionNamespace getVariable ["ACME_tbi_defaultMAP", 70]};

private _bp = [];
if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
    _bp = [_patient] call ace_medical_status_fnc_getBloodPressure;
};
if (_bp isEqualType [] && {count _bp >= 2}) exitWith {
    // the getbloodpressure of ACE returns [diastolic, systolic], with the diastolic first. this was reversed, which read
    // the MAP about 14 mmhg high: for 127 over 85 it gave 127+(85-127)/3, which is 113, instead of the correct
    // 85+(127-85)/3, which is 99.
    _bp params ["_dia", "_sys"];
    _dia + ((_sys - _dia) / 3)
};
missionNamespace getVariable ["ACME_tbi_defaultMAP", 70]
