// B11: pair each provider's treatment events before routing to the patient owner.
["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _patient || {!local _medic} || {!(_patient getVariable ["ACME_headElevated", false])}) exitWith {};
    private _cfg = configFile >> "ace_medical_treatment_actions" >> _classname;
    private _roll = (getNumber (_cfg >> "ACM_rollToBack")) > 0;
    private _isBody = if (_bodyPart isEqualType "") then {toLower _bodyPart == "body"} else {_bodyPart == 1};
    if !(_roll || _isBody) exitWith {};
    private _serial = (missionNamespace getVariable ["ACME_headElev_treatmentSerial", 0]) + 1;
    missionNamespace setVariable ["ACME_headElev_treatmentSerial", _serial];
    private _id = format ["%1:%2:%3", clientOwner, netId _medic, _serial];
    private _token = _patient getVariable ["ACME_headElev_poseToken", ""];
    _medic setVariable ["ACME_headElev_treatment", [_patient, _classname, _id, _token]];
    [_patient, _medic, _id, true, _token] call ACME_fnc_headElevTreatmentEvent;
}] call CBA_fnc_addEventHandler;
{
    [_x, {
        params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
        if (!local _medic) exitWith {};
        private _entry = _medic getVariable ["ACME_headElev_treatment", []];
        if ((_entry param [0, objNull]) != _patient || {(_entry param [1, ""]) != _classname}) exitWith {};
        _medic setVariable ["ACME_headElev_treatment", []];
        [_patient, _medic, _entry select 2, false, _entry select 3] call ACME_fnc_headElevTreatmentEvent;
    }] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];
