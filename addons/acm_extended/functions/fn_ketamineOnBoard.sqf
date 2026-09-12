/* B14: legacy IV induction-load units, NOT mg. Native counts supply dose/weight/onset/washout.
   IV calibration is retained (7 ~= 1.75 mg/kg). IM reaches the same load at 3 mg/kg.
   Esketamine remains a fixed nasal product: a modest route-specific adjunct, not an IV dose. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {isNil "ace_medical_status_fnc_getMedicationCount"}) exitWith {0};
private _get = {
    params ["_class"];
    private _v = [_patient, _class, false] call ace_medical_status_fnc_getMedicationCount;
    if !(_v isEqualType 0 && {finite _v}) exitWith {0};
    _v max 0
};
(["Ketamine_IV"] call _get) * 0.8
    + (["Ketamine"] call _get) * 1.75
    + (["Esketamine"] call _get) * 1.2
