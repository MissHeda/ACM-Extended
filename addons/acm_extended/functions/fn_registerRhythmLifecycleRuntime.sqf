// custom cardiac rhythms.
// the three ACM waveform generators are overridden at compile time through CfgFunctions, because ACM compiles
// its functions final and a runtime reassignment is ignored silently. the ekg override delegates codes of 100
// and above to ACME_fnc_genRhythmEKG. the pleth and capno overrides render a custom code as sinus. there is
// nothing to install here at runtime.

// sustain the active custom rhythms. this holds the display rhythm and drives hr to the target.
[{call ACME_fnc_rhythmTick}, 0.5, []] call CBA_fnc_addPerFrameHandler;
// physical awake-but-lying state change. it runs where the patient is local.
["ACME_obtundedApply", {_this call ACME_fnc_obtundedApply}] call CBA_fnc_addEventHandler;

// reset our per-life patient state on respawn. these vars live on the unit and otherwise bleed into the next
// life, so an obtunded or arrhythmic prior life carries over. this clears both units and force-removes the
// client-side obtundation screen effects on the fresh life.
// the mission-level handler is "EntityRespawned", with params [newentity, oldentity]. the "Respawn" enum exists
// only as a unit event handler. EntityRespawned fires for every entity, so we guard to humans only.
addMissionEventHandler ["EntityRespawned", {
    params ["_newUnit", "_oldUnit"];
    if !(_newUnit isKindOf "CAManBase") exitWith {};
    {
        if (!isNull _x) then {
            if (local _x) then {
                [_x] call ACME_fnc_clearAllAilments;  // B57: both the old body and new life are scrubbed
            };
            // clearAllAilments resets both the new life and the old body; ACME injury artifacts never survive a reset boundary.
            // Keep every machine's immediate local reset, but only the current owner
            // publishes it. Do not fan the same public reset out from every client.
            [_x, false, false, "", -1, local _x] call ACME_fnc_obtundedStateCommit;
            _x setVariable ["ACME_obtunded_forcedBack", false, local _x];
            [_x, 0, local _x, false] call ACME_fnc_rhythmActiveCommit;
            _x setVariable ["ACME_rhythm_targetHR", 0, local _x];
            _x setVariable ["ACME_rhythm_bpOffset", 0, local _x];
            _x setVariable ["ACME_rhythm_savedTargetHR", nil, local _x];
            _x setVariable ["ACME_rhythm_obtundUntil", -1, local _x];
            [_x, "", -1, local _x, false] call ACME_fnc_rhythmNativeHoldCommit;
            [_x, 0, false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
            [_x, 0, false, false] call ACME_fnc_rhythmNativeShockGraceCommit;
            [_x, [["cardiacRhythmState", 0]], local _x] call ACM_circulation_fnc_setRuntimeState;
            [_x, false, false, false, local _x, false] call ACME_fnc_nrbStateCommit;
            [_x, "", local _x, false] call ACME_fnc_hpmkStateCommit;
            _x setVariable ["ACME_emma_bvmAttached", false, local _x];
            _x setVariable ["ACME_emma_lastPatient", objNull];
            _x setVariable ["ACME_emma_lastBag", -1e9];
        };
    } forEach [_oldUnit, _newUnit];
    // a freshly respawned player can still be transferring ownership when EntityRespawned fires. the local-gated
    // clearAllAilments above therefore often runs on the server, where the new unit is momentarily local, while the
    // medical and rhythm engine of the player runs on their client. that is why AFib could re-seat from uncleared
    // client-side rhythm state. this re-runs the reset a beat later, by which point ownership has settled, so it
    // lands on the real owner. the handler registers on every machine, so the local check passes on whichever one
    // now owns the unit. clearAllAilments also resets junctional state; no duplicate all-client broadcast is needed.
    // there is no remoteexec, so there is no cfgremoteexec whitelist dependency on a locked server.
    [{
        params ["_u"];
        if (isNull _u || {!alive _u}) exitWith {};
        if (local _u) then {
            [_u] call ACME_fnc_clearAllAilments;
        };
    }, [_newUnit], 2.0] call CBA_fnc_waitAndExecute;
    [_newUnit, false] call ACME_fnc_obtundedApply;  // tear down pp/sound effects on the new life
    if (!isNil "ACME_hpmk_activePatients") then { ACME_hpmk_activePatients = ACME_hpmk_activePatients - [_oldUnit, _newUnit]; };
}];


// clear the native rhythm persistence after a confirmed ROSC. vt, vf and PVT must not self-clear from an hr
// wobble, but ACM's successful resuscitation pathway must be able to restore an organized rhythm.
["ace_medical_CPRSucceeded", {
    params ["_patient"];
    if (isNull _patient) exitWith {};
    [_patient, CBA_missionTime + (missionNamespace getVariable ["ACME_rhythmNativeShockGraceSec", 10]), true, false] call ACME_fnc_rhythmNativeShockGraceCommit;
    [_patient, "", -1, true, false] call ACME_fnc_rhythmNativeHoldCommit;
    [_patient, 0, false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    if (local _patient) then {_patient setVariable ["ACME_peaElectricalHR", nil, true];};
}] call CBA_fnc_addEventHandler;
