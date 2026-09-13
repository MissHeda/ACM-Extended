// B72 provider stance release. ACME starts ordinary on-foot treatments from empty-hands crouch, but setUnitPos is
// only an entry guard, never a permanent player lock. Once ACE reports success/failure, release AUTO after the
// native crouched end-animation handoff. Do not interfere with head-lift or another ACME-owned finite pose.
//
// Direct Pressure integration: another treatment owns the provider animation the instant ACE says it started.
// Retire DP's held-animation generation at that boundary so a tourniquet, bandage, IV action, etc. can never be
// overwritten by the short ACME_DirectPressureHold reassert worker. DP itself remains clinically active while the
// provider stays stationary and may resume after the treatment; any movement input hard-releases it in its own tick.
["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _medic || {!local _medic} || {!(_medic getVariable ["ACME_DP_Active", false])}) exitWith {};
    if (_classname == "ACME_DirectPressure") exitWith {};

    _medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];
    _medic setVariable ["ACME_DP_InPose", false];
    _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
    _medic setVariable ["ACME_DP_LastPoseAssert", 0];
}] call CBA_fnc_addEventHandler;

{
    [_x, {
        params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
        if (isNull _medic || {!local _medic} || {!alive _medic} || {!isNull objectParent _medic}
            || {_classname in ["ACME_ElevateHead", "ACME_LowerHead"]}) exitWith {};

        // A completed/failed treatment gets a fresh quiet window before Direct Pressure is allowed to visibly resume.
        // This is what makes back-to-back actions safe: a long tourniquet does not finish and immediately have the old
        // pressure pose reassert on the exact frame the provider is trying to start the next intervention.
        if (_medic getVariable ["ACME_DP_Active", false]) then {
            _medic setVariable ["ACME_dah_gen", (_medic getVariable ["ACME_dah_gen", 0]) + 1, false];
            _medic setVariable ["ACME_DP_InPose", false];
            _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime];
            _medic setVariable ["ACME_DP_LastPoseAssert", 0];
        };

        [{
            params ["_m"];
            if (isNull _m || {!local _m} || {!alive _m} || {!isNull objectParent _m}) exitWith {};
            if ((_m getVariable ["ACME_treatmentPoseState", []]) isNotEqualTo []
                || {_m getVariable ["ACME_rollProviderActive", false]}
                || {_m getVariable ["ACME_headElev_seqActive", false]}) exitWith {};
            _m setUnitPos "AUTO";
        }, [_medic], 0.12] call CBA_fnc_waitAndExecute;
    }] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];
