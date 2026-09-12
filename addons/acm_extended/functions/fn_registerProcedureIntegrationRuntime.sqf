["ACM_circulation_setIVLocal", {
    params ["_medic", "_patient", "_bodyPart", "_type", "_iv", "_accessSite"];
    if (!isNull _patient && {local _patient} && {!_iv} && {_type > 0}) then {
        [_patient, _bodyPart, "placement"] call ACME_fnc_ioPainResponse;
    };
}] call CBA_fnc_addEventHandler;


["ACME_DP_fracturePain", {_this call ACME_fnc_directPressureFracturePain}] call CBA_fnc_addEventHandler;

// NA3 legacy integration event. Never trim unrelated medication history.
["ACME_infusionPulse", {
    params ["_patient", "_part", "_class", "_dose"];
    if (local _patient && {_dose > 0}) then {
        private _old = missionNamespace getVariable ["ACME_vesicant_infusionDelivery", false];
        missionNamespace setVariable ["ACME_vesicant_infusionDelivery", true];
        [_patient, _part, _class, _dose, true] call ace_medical_treatment_fnc_medicationLocal;
        missionNamespace setVariable ["ACME_vesicant_infusionDelivery", _old];
    };
}] call CBA_fnc_addEventHandler;

// B45: IO bag pain is triggered from actual admitted volume inside fn_getBloodVolumeChange. The old 0.5 s
// whole-unit watcher is removed so merely opening an IO clamp cannot cause pain/syncope before fluid settles.

// head-positioned positional voice for the patient respiration sounds, the inhale, the exhale and the ROSC
// gasp. it plays the sound from a #dynamicsound attached at the head selection of the patient, so it reads as
// coming from the mouth. ACE's forcesay3d attaches at the camera point instead and falls back to the model
// origin at the feet. this uses the same client-gated pattern as ACE's handler and fires through targetevent to
// nearby players.
["ACME_breathSay3D", {
    params ["_unit", "_sound", "_distance"];
    if (isNull _unit) exitWith {};
    if (ACE_player distance _unit > _distance) exitWith {};
    private _dummy = "#dynamicsound" createVehicleLocal [0, 0, 0];
    _dummy attachTo [_unit, (_unit selectionPosition "head")];
    _dummy say3D [_sound, _distance, 1, false];
    [{ params ["_d"]; detach _d; deleteVehicle _d; }, [_dummy], 5] call CBA_fnc_waitAndExecute;
}] call CBA_fnc_addEventHandler;
