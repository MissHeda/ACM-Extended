// open the thoracostomy mini-game, idd 86600. it mirrors fn_chestsealopen: stash the medic and patient on
// uinamespace, then createdialog after a short beat, and after lowering an elevated head, the same as the chest
// seal.
// call it as [_medic, _patient, _bodyPart] call ACME_fnc_thoraOpen.
params ["_medic", "_patient", ["_bodyPart", ""]];
if (isNull _patient || {isNull _medic}) exitWith {};
if !([_medic, _patient] call ACME_fnc_thoraCanOpen) exitWith {};
private _ecgJostleKey = "ui:thora:" + str clientOwner;
[_patient, _ecgJostleKey, true] call ACME_fnc_ecgJostleRequest;

uiNamespace setVariable ["ACME_Thora_Medic", _medic];
uiNamespace setVariable ["ACME_Thora_Patient", _patient];
uiNamespace setVariable ["ACME_Thora_BodyPart", _bodyPart];

private _wait = 0.1;
if (_patient getVariable ["ACME_headElevated", false]) then {
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
    [_patient] call ACME_fnc_headElevSuspend;
    _wait = (missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 0.6]) + 0.25;
};
// a spike. it is routed through fn_minigameopen, which opens this as a dialog by default and as a display when
// ACME_minigame_displayMode is on.
// display mode is what would let the real interaction menu of ACE open over the panel instead of closing it. the
// thoracostomy comes first, because it is the simplest of the three: if the mouse does not survive, only one
// minigame is affected and the switch turns it straight back.
[{["ACME_Thoracostomy_Dialog"] call ACME_fnc_minigameOpen;}, [], _wait] call CBA_fnc_waitAndExecute;
