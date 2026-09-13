// the shared per-frame mover for direct pressure. It watches hard hold-ending conditions: provider down, patient
// gone, or distance broken. Movement does NOT end Direct Pressure. It only yields the held animation immediately;
// once the provider stops moving and settles again, the hold may reapply after the normal idle delay.
// Once pressure has been held past 15 s, it makes a very-high-chance clot attempt every couple of seconds.
params ["_args", "_pfhId"];
_args params ["_medic", "_patient", "_bodyPart", "_mode"];

if !(_medic getVariable ["ACME_DP_Active", false]) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler; };
// the system toggle. turning direct pressure off mid-hold must release the medic rather than freeze them holding a
// wound forever, so this uses the normal stop path rather than a bare exitwith.
if !(missionNamespace getVariable ["ACME_sys_dp", true]) exitWith {
    [false, _medic] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

private _stop = "";
if (!alive _medic || {_medic getVariable ["ACE_isUnconscious", false]}) then { _stop = "down"; };
if (_stop == "" && {isNull _patient}) then { _stop = "patient"; };

private _leash = if (_mode == "torso") then { 2.2 } else { missionNamespace getVariable ["ACME_DP_leashDist", 1.7] };
// Match the AED lead/leash contract: the hold is valid only while provider and patient remain in the same
// vehicle context and inside the treatment radius. This keeps the explicit Stop Direct Pressure action while
// making walking away far enough, entering a vehicle, or leaving the patient's vehicle release pressure.
private _medicVehicle = objectParent _medic;
private _patientVehicle = objectParent _patient;
if (_stop == "" && {_medicVehicle isNotEqualTo _patientVehicle}) then { _stop = "far"; };
if (_stop == "" && {(_medic distance _patient) > _leash}) then { _stop = "far"; };

if (_stop != "") exitWith {
    switch (_stop) do {
        case "far": { ["Direct pressure released.", 2, _medic] call ace_common_fnc_displayTextStructured; };
        default {};
    };
    [true, _medic] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

// Direct Pressure never owns weapon selection. No entry, resume, or tick path should call putWeaponAway or restore
// a weapon. The selected weapon is left untouched while the CfgMoves state temporarily supplies the treatment pose.

// limb and torso: the pose helper owns movement escape and treatment yielding. Any movement input retires the
// held-animation generation immediately and exits the pose, but the clinical Direct Pressure state stays active.
// When the provider stops moving, faces the patient and remains idle for the configured delay, the animation can
// reapply. This preserves the original resumable behavior without allowing the held pose to trap movement.
if (_mode in ["limb", "torso"]) then {
    [_medic, _patient] call ACME_fnc_directPressurePose;
};

// Paused pressure does not clot. A torso hold also pauses its therapeutic timer while the same client is running
// another finite/continuous treatment; the hold state remains available to resume afterwards.
if (_medic getVariable ["ACME_DP_Paused", false]) exitWith {};
if (_mode == "torso" && {
    (_medic getVariable ["ACME_treatmentPreflightActive", false])
    || {(_medic getVariable ["ace_medical_treatment_endInAnim", ""]) != ""}
    || {missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]}
}) exitWith {};

private _held = CBA_missionTime - (_medic getVariable ["ACME_DP_Start", CBA_missionTime]);
if (_held < 15) exitWith {};

if (CBA_missionTime < (_medic getVariable ["ACME_DP_NextClot", 0])) exitWith {};
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 2];  // re-attempt every 2 s past the 15 s mark.

// a very high chance: clot up to 2 wounds of any severity on the held part. manual clots are unstable, with no
// bandage, so they can re-open, which is realistic for bare-handed pressure.
[_patient, _bodyPart, 2, 3, true, false] call ACM_damage_fnc_clotWoundsOnBodyPart;
