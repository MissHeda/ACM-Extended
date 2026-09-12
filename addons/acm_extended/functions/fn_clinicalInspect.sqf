/* Read-only staging diagnostic. No mutation, treatment, healing or network publication. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {createHashMapFromArray [["error", "No patient"]]};
private _issues = [];
private _raw = [_patient] call ACME_fnc_rhythmNative;
private _effective = [_patient] call ACME_fnc_rhythmGet;
private _arrest = _patient getVariable ["ace_medical_inCardiacArrest", false];
if (!_arrest && {_raw in [1,2,3,5]} && {alive _patient}) then {_issues pushBack "Native pulseless rhythm without arrest";};
if (_arrest && {_effective in [0,4,100,101,103,104]}) then {_issues pushBack "Perfusing rhythm while native arrest remains set";};
{
    private _v = _patient getVariable [_x, 0];
    if !(_v isEqualType 0 && {finite _v} && {_v >= 0}) then {_issues pushBack format ["Invalid %1 = %2", _x, _v];};
} forEach ["ace_medical_bloodVolume", "ace_medical_heartRate", "ACM_breathing_RespirationRate", "ACM_circulation_Blood_Volume", "ACM_circulation_Saline_Volume", "ACM_circulation_Plasma_Volume"];
private _ledger = _patient getVariable ["ACME_infusion_BagMedications", []];
{
    private _total = _x param [13, 0]; private _remaining = _x param [14, 0];
    private _lost = _x param [24, 0]; private _systemic = _x param [25, 0];
    if (abs (_total - (_remaining + _lost + _systemic)) > 0.001) then {_issues pushBack format ["Dose ledger mismatch %1", _x select 0];};
} forEach _ledger;
private _out = createHashMapFromArray [
    ["patient", netId _patient], ["owner", owner _patient], ["local", local _patient], ["epoch", [_patient] call ACME_fnc_clinicalEpoch],
    ["nativeRhythm", _raw], ["effectiveRhythm", _effective], ["arrest", _arrest], ["pulse", [_patient] call ACM_circulation_fnc_hasPulse],
    ["HR", _patient getVariable ["ace_medical_heartRate",0]], ["BP", [_patient] call ace_medical_status_fnc_getBloodPressure],
    ["RR", _patient getVariable ["ACM_breathing_RespirationRate",0]], ["neuralRR", _patient getVariable ["ACME_resp_neuralRR",0]],
    ["EtCO2", [_patient] call ACM_breathing_fnc_getEtCO2], ["issues", _issues]
];

_out
