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

// The minigame owns one temporary casualty workspace. The patient owner lowers Semi-Fowler once, moves any worn
// plate carrier beyond the head, and acknowledges when that workspace is ready. During the minigame only the normal
// front/back roll states are allowed to move the casualty.
private _serial = (uiNamespace getVariable ["ACME_CS_SessionSerial", 0]) + 1;
uiNamespace setVariable ["ACME_CS_SessionSerial", _serial];
private _sessionToken = format ["%1:%2:%3", clientOwner, CBA_missionTime, _serial];
uiNamespace setVariable ["ACME_CS_SessionToken", _sessionToken];
[_patient, "chestSealPatientBegin", [_patient, _sessionToken]] call ACME_fnc_ownerDispatch;

[{
    params ["_p", "_tok"];
    if (isNull _p) exitWith {true};
    private _tokens = _p getVariable ["ACME_CS_ProcedureTokens", []];
    private _readyAt = _p getVariable ["ACME_CS_ProcedureReadyAt", CBA_missionTime + 99];
    (_tok in _tokens) && {CBA_missionTime >= _readyAt}
}, {
    ["ACME_ChestSeal_Dialog"] call ACME_fnc_minigameOpen;
}, [_patient, _sessionToken], 4, {
    // Owner routing should normally acknowledge in one frame. A timeout must not strand the treatment callback.
    ["ACME_ChestSeal_Dialog"] call ACME_fnc_minigameOpen;
}] call CBA_fnc_waitUntilAndExecute;
