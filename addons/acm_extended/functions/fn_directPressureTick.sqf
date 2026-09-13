// Shared direct-pressure per-frame worker.
// Torso pressure is an exclusive active maneuver. Limb/head pressure is non-exclusive and yields its provider pose
// to other treatments. Any real movement attempt releases direct pressure immediately so the first movement input
// is never swallowed by the looping treatment animation.
params ["_args", "_pfhId"];
_args params ["_medic", "_patient", "_bodyPart", "_mode"];

if !(_medic getVariable ["ACME_DP_Active", false]) exitWith {[_pfhId] call CBA_fnc_removePerFrameHandler;};
if !(missionNamespace getVariable ["ACME_sys_dp", true]) exitWith {
    [false, _medic, false] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

private _stop = "";
if (!alive _medic || {_medic getVariable ["ACE_isUnconscious", false]}) then {_stop = "down";};
if (_stop == "" && {isNull _patient}) then {_stop = "patient";};

private _leash = if (_mode == "torso") then {2.2} else {missionNamespace getVariable ["ACME_DP_leashDist", 1.7]};
private _medicVehicle = objectParent _medic;
private _patientVehicle = objectParent _patient;
if (_stop == "" && {_medicVehicle isNotEqualTo _patientVehicle}) then {_stop = "far";};
if (_stop == "" && {(_medic distance _patient) > _leash}) then {_stop = "far";};

if (_stop != "") exitWith {
    if (_stop == "far") then {["Direct pressure released.", 2, _medic] call ace_common_fnc_displayTextStructured;};
    [true, _medic, false] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

// Read movement intent every rendered frame. Torso pressure is a BVM-style maneuver, so attempting to move
// immediately cancels it. Limb/head pressure is deliberately non-exclusive: its pose helper drops the held
// animation on movement without killing the clinical pressure state, which keeps movement and other treatments
// responsive instead of making the provider feel welded in place.
private _moveInput = (inputAction "MoveForward") + (inputAction "MoveBack")
                   + (inputAction "MoveLeft") + (inputAction "MoveRight")
                   + (inputAction "MoveFastForward") + (inputAction "MoveSlowForward")
                   + (inputAction "Evasive");
if (_mode == "torso" && {_moveInput > 0.01}) exitWith {
    [true, _medic, false] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

// Limb/head pressure remains non-exclusive. This helper yields immediately to movement and treatments, then can
// reapply only after the provider is stationary again.
if (_mode == "limb") then {[_medic, _patient] call ACME_fnc_directPressurePose;};

if (_medic getVariable ["ACME_DP_Paused", false]) exitWith {};

// A torso hold is the continuous action itself, so its own ACM_core_ContinuousAction_Active flag must not pause its
// clot timer. Other competing treatment ownership cannot occur while the torso maneuver owns that gate.
if (_mode != "torso" && {
    (_medic getVariable ["ACME_treatmentPreflightActive", false])
    || {(_medic getVariable ["ace_medical_treatment_endInAnim", ""]) != ""}
    || {missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]}
}) exitWith {};

private _held = CBA_missionTime - (_medic getVariable ["ACME_DP_Start", CBA_missionTime]);
if (_held < 15) exitWith {};
if (CBA_missionTime < (_medic getVariable ["ACME_DP_NextClot", 0])) exitWith {};
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 2];

[_patient, _bodyPart, 2, 3, true, false] call ACM_damage_fnc_clotWoundsOnBodyPart;
