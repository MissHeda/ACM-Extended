// Roll a prone casualty supine before opening the auscultation minigame.
// Uses the same provider theatre and patient roll primitive as chest-seal Flip.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "Body", [""]]
];
if (isNull _medic || {isNull _patient} || {!local _medic} || {!alive _medic} || {!alive _patient}) exitWith {};

private _actual = [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide;
if (_actual != "back" || {!([_patient] call ACME_fnc_chestSealCanPhysicalRoll)}) exitWith {
    [_medic, _patient, _bodyPart, true] call ACM_breathing_fnc_useStethoscope;
};

private _started = [_medic, "stethoscopeEntry", _patient] call ACME_fnc_rollProviderStart;
if (!_started) exitWith {
    ["Unable to reposition patient for auscultation.", 2, _medic] call ace_common_fnc_displayTextStructured;
    ["ace_treatmentFailed", [_medic, _patient, _bodyPart, "ACM_ContinuousAction", "", "", false]] call CBA_fnc_localEvent;
    ["ACM_core_openMedicalMenu", _patient] call CBA_fnc_localEvent;
};

private _pose = _medic getVariable ["ACME_treatmentPoseState", []];
private _epoch = _pose param [0, -1];
private _rollToken = _medic getVariable ["ACME_rollProviderToken", ""];
if (_epoch < 0 || {_rollToken == ""}) exitWith {
    ["ace_treatmentFailed", [_medic, _patient, _bodyPart, "ACM_ContinuousAction", "", "", false]] call CBA_fnc_localEvent;
};

private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
if !(_rollTime isEqualType 0 && {finite _rollTime}) then {_rollTime = 1.85;};
_rollTime = (_rollTime max 0.1) min 5;

private _args = [_medic, _patient, _bodyPart, _epoch, _rollToken, _rollTime, -1, diag_tickTime + 5.5];
[{_this call ACME_fnc_stethoscopeEntryFlipTick;}, 0, _args] call CBA_fnc_addPerFrameHandler;
