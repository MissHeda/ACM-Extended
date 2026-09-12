params ["_medic", "_patient", ["_bodyPart", ""], ["_startTool", "seal"]];
if (isNull _patient || {isNull _medic}) exitWith {};
private _ecgJostleKey = "ui:chest:" + str clientOwner;
[_patient, _ecgJostleKey, true] call ACME_fnc_ecgJostleRequest;

if !(missionNamespace getVariable ["ACME_sys_chestSeal", true]) exitWith {
    if (_startTool == "spear") then {
        if (([_medic, "ACME_NARSPEAR"] call ace_common_fnc_getCountOfItem) > 0) then {
            _medic removeItem "ACME_NARSPEAR";
            [_medic, _patient] call ACM_breathing_fnc_performNCD;
        };
    } else {
        if (([_medic, "ACM_ChestSeal"] call ace_common_fnc_getCountOfItem) > 0) then {
            _medic removeItem "ACM_ChestSeal";
            [_medic, _patient] call ACM_breathing_fnc_applyChestSeal;
        };
    };
};

uiNamespace setVariable ["ACME_CS_Medic", _medic];
uiNamespace setVariable ["ACME_CS_Patient", _patient];
uiNamespace setVariable ["ACME_CS_BodyPart", _bodyPart];
uiNamespace setVariable ["ACME_CS_StartTool", _startTool];

// if the head of the casualty is elevated, play the lower head pre-animation first, laying them flat, and only open
// the mini-game once it has had time to play. otherwise open after the usual short beat.
private _wait = 0.1;
if (_patient getVariable ["ACME_headElevated", false]) then {
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
    [_patient] call ACME_fnc_headElevSuspend;
    // Suspend delegates dead patients to the existing death-release cleanup;
    // only a living patient needs time for a lower-head animation.
    if (alive _patient && {(lifeState _patient) != "DEAD"}) then {
        _wait = (missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 0.6]) + 0.25;
    };
};
[{["ACME_ChestSeal_Dialog"] call ACME_fnc_minigameOpen;}, [], _wait] call CBA_fnc_waitAndExecute;
