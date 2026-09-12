// B72 provider stance release. ACME starts ordinary on-foot treatments from empty-hands crouch, but setUnitPos is
// only an entry guard, never a permanent player lock. Once ACE reports success/failure, release AUTO after the
// native crouched end-animation handoff. Do not interfere with head-lift or another ACME-owned finite pose.
{
    [_x, {
        params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
        if (isNull _medic || {!local _medic} || {!alive _medic} || {!isNull objectParent _medic}
            || {_classname in ["ACME_ElevateHead", "ACME_LowerHead"]}) exitWith {};
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
