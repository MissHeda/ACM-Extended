// B39: every ACM treatment that physically requests a roll-to-back uses one provider theatre.
// This runs independently of head elevation and is local-only; the patient reposition remains ACM-owned.
["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _medic || {!local _medic} || {_classname == ""}) exitWith {};
    private _cfgRollB39 = configFile >> "ace_medical_treatment_actions" >> _classname >> "ACM_rollToBack";
    // B47 precedence: an action-specific pose started by callbackStart owns the provider.  Do not let the generic
    // roll theatre replace Check Airway/Response/Inspect Chest. UseStethoscope starts its held pose when the
    // minigame opens a frame later, so suppress the generic provider roll there too. Patient rolling remains ACM-owned.
    private _poseOwned = (_medic getVariable ["ACME_treatmentPoseState", []]) isNotEqualTo [];
    private _isStethoscope = toLower _classname == "usestethoscope";
    private _rollsPatient = (getNumber _cfgRollB39) > 0;
    if (_rollsPatient && {!_poseOwned} && {!_isStethoscope}) then {
        [_medic, _classname, _patient] call ACME_fnc_rollProviderStart;
    };
}] call CBA_fnc_addEventHandler;
