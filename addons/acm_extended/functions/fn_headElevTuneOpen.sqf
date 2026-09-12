// open the live head-elevation tilt tuner for the casualty whose head was just elevated.
// the action callback args are [_medic, _patient, _bodyPart].
params [["_medic", ACE_player, [objNull]], ["_patient", objNull, [objNull]]];
if !([] call ACME_fnc_debugEnabled) exitWith {};  // debug-gated tuner
if (isNull _patient) then { _patient = missionNamespace getVariable ["ACME_headElev_TunePatient", objNull]; };
if (isNull _patient || {!(_patient getVariable ["ACME_headElevated", false])}) exitWith {
    ["Elevate a casualty's head before opening the tilt tuner.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
};
missionNamespace setVariable ["ACME_headElev_TunePatient", _patient];
missionNamespace setVariable ["ACME_headElev_tuning", true];
// defer the dialog. this runs inside the callbacksuccess of the ACE treatment action, and ACE closes interaction
// dialogs a frame or two after the callback, so opening immediately makes the tuner flash up and vanish. a short
// delay lets ACE finish tearing down before we create our dialog.
[{
    params ["_patient"];
    if (isNull _patient || {!(_patient getVariable ["ACME_headElevated", false])}) exitWith {};
    createDialog "ACME_HeadElev_Tuner";
}, [_patient], 0.35] call CBA_fnc_waitAndExecute;
