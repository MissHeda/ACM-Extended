// a CfgFunctions override of acm_airway_fnc_handlesuction, the callbacksuccess of the suction action, fired when the
// suction timer completes.
// we replicate the logic of ACM verbatim, de-macroed, and add one thing: a suction off sfx the instant an ACCUVAC,
// device type 1, finishes.
// we hook here rather than the handlesuctionlocal event, because that event only fires when an obstruction was
// actually cleared and carries no device type, and the power-down sound is wanted on every ACCUVAC completion. keep
// it in sync if ACM changes handlesuction.
// _this is [_medic, _patient, _type], where _type is 0 for the suction bag and 1 for the ACCUVAC.
params ["_medic", "_patient", "_type"];

// neither suction action routes through here any more, because both open the minigame directly with no timer. this
// path is now only reached by something else calling the function of ACM by name, which is why it is kept rather
// than deleted.


private _hint = format ["%1<br />%2", localize "STR_ACM_Airway_Suction_Finished", localize "STR_ACM_Airway_Suction_AirwayIsClear"];
private _device = ([localize "STR_ACM_Airway_SuctionBag_Short", localize "STR_ACM_Airway_ACCUVAC"] select _type);

if (((_patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0]) + (_patient getVariable ["ACM_airway_AirwayObstructionBlood_State", 0])) > 0) then {
    ["ACM_airway_handleSuctionLocal", [_patient], _patient] call CBA_fnc_targetEvent;

    _hint = format ["%1<br />%2", localize "STR_ACM_Airway_Suction_Finished", localize "STR_ACM_Airway_Suction_AirwayHasBeenCleared"];
};

[_hint, 2, _medic] call ace_common_fnc_displayTextStructured;
[_patient, "activity", localize "STR_ACE_Medical_Treatment_Activity_usedItem", [[_medic, false, true] call ace_common_fnc_getName, _device]] call ace_medical_treatment_fnc_addToLog;

// ACME: the ACCUVAC power-down sfx, right as the suction timer completes. it plays through the registered CfgSounds
// class, ACM_Suction_Off, so the sound is wired through config rather than a bare file path.
if (_type == 1 && {!isNull _medic}) then {
    [_medic, "ACM_Suction_Off"] remoteExec ["ACM_airway_fnc_remoteSay3D", 0];
};
