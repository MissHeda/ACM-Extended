// Attach the reusable EMMA to the patient's ET tube or i-gel.
// if the EMMA of the medic was already attached to their own BVM, this moves it off the BVM and onto the patient.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params [["_medic", objNull], ["_patient", objNull], ["_bodyPart", "head"], ["_required", "", [""]]];
private _airway = [_patient] call ACME_fnc_emmaAirwayKind;
private _name = if (_airway == "ett") then {"ET tube"} else {"i-gel"};

if !([_medic, _patient, _required] call ACME_fnc_emmaCanAttachIGel) exitWith {
    ["Cannot attach EMMA: check the airway, device and treatment range.", 2, _medic] call ace_common_fnc_displayTextStructured;
};

// move the device off the medic BVM route and reset the capture, so the HUD cannot inherit the old route.
_medic setVariable ["ACME_emma_bvmAttached", false, true];
_medic setVariable ["ACME_emma_route", "igel", false];
_medic setVariable ["ACME_emma_capPatient", objNull, false];
_medic setVariable ["ACME_emma_lastPatient", objNull, false];
_medic setVariable ["ACME_emma_lastBag", -1e9, false];

[_medic, _patient] call ACME_fnc_emmaMarkContact;

[_patient, true, CBA_missionTime, getPlayerUID _medic, [_medic, false, true] call ace_common_fnc_getName] call ACME_fnc_emmaIGelStateCommit;

[format ["EMMA attached to their %1.", _name], 2, _medic] call ace_common_fnc_displayTextStructured;
