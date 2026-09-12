// B19 ECG motion artifact: stock ACE timed treatments publish a network-visible lease on the patient owner.
// Success/failure releases it; a bounded lease expiry also prevents stuck artifact after interruption/disconnect.
["ace_treatmentStarted", {
    params ["_medic","_patient","_bodyPart","_classname"];
    if (isNull _patient) exitWith {};
    private _key = format ["ace:%1:%2:%3", netId _medic, _classname, _bodyPart];
    [_patient,_key,true] call ACME_fnc_ecgJostleRequest;
}] call CBA_fnc_addEventHandler;
private _acmeStopTreatmentJostle = {
    params ["_medic","_patient","_bodyPart","_classname"];
    if (isNull _patient) exitWith {};
    private _key = format ["ace:%1:%2:%3", netId _medic, _classname, _bodyPart];
    [_patient,_key,false] call ACME_fnc_ecgJostleRequest;
};
["ace_treatmentSucceded", _acmeStopTreatmentJostle] call CBA_fnc_addEventHandler;
["ace_treatmentFailed", _acmeStopTreatmentJostle] call CBA_fnc_addEventHandler;
ACME_ecgJostleLeaseSec = 180;
