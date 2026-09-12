// reset a megacode dummy to a clean baseline, operating directly on the unit. it runs where the dummy is local,
// meaning the server or owner, and has no ui and no uinamespace, so it can be driven by the death handler as well
// as the RESET button of the panel.
// it clears wounds, restores the normal vitals and sinus, clears the feature states, roscs and wakes, re-settles the
// lying pose, and re-asserts the plot armor of the manikin so it stays un-killable.
// _this is [_d].
params ["_d"];
if (isNull _d || {!local _d}) exitWith {};

// a truly-dead manikin, killed by ACE, such as from a fatal wound when the fatalinjuriesai of the mission is always,
// a path the per-unit plot armor of ACM cannot block, cannot be revived in place. stand up a fresh one instead.
// this is what the RESET button and the delayed reset of the death handler both land on when the manikin is
// actually dead.
if (!alive _d) exitWith { [_d] call ACME_fnc_megacodeRespawn; };

[_d] call ACME_fnc_megacodeClearWounds;

{
    _x params ["_v", "_dv"];
    _d setVariable [_v, _dv, true];
} forEach [
    ["ACME_MC_HR", 78], ["ACME_MC_SpO2", 98], ["ACME_MC_SBP", 122], ["ACME_MC_DBP", 78],
    ["ACME_MC_RR", 14], ["ACME_MC_EtCO2", 38], ["ACME_MC_Temp", 37.0],
    // the ramp targets reset alongside the live values, so the keeper does not ease them back off baseline.
    ["ACME_MC_HRTgt", 78], ["ACME_MC_SpO2Tgt", 98], ["ACME_MC_SBPTgt", 122], ["ACME_MC_DBPTgt", 78],
    ["ACME_MC_RRTgt", 14], ["ACME_MC_EtCO2Tgt", 38],
    ["ACME_MC_rhythm", "sinus"], ["ACME_MC_pulseless", false], ["ACME_MC_airway", "patent"],
    ["ACME_MC_ICP", 10], ["ACME_MC_GCS", 15], ["ACME_MC_herniation", false], ["ACME_MC_seizure", false],
    ["ACME_MC_posturing", "none"], ["ACME_MC_pupils", "equal"], ["ACME_MC_airwayObstruct", false],
    ["ACME_MC_pneumoLeft", false], ["ACME_MC_pneumoRight", false]
];
[_d, [["heartRate", 78], ["respirationRate", 14], ["oxygenSaturation", 98]], true] call ACM_core_fnc_setTargetVitalsState;
[_d, 0] call ACME_fnc_rhythmSet;
[_d, 0, true, false] call ACME_fnc_rhythmActiveCommit;
[_d, [["blood", 0], ["vomit", 0], ["collapse", 0]], true] call ACM_airway_fnc_setAirwayState;
[_d, "ncd"] call ACME_fnc_megacodeChestInjury;
if (_d getVariable ["ace_medical_inCardiacArrest", false]) then {
    [_d, 0, false] call ACME_fnc_megacodeArrest;
};
if (_d getVariable ["ACE_isUnconscious", false]) then {
    [_d, false] call ace_medical_status_fnc_setUnconsciousState;
};

// clear the fatal clock and the dying latch, and re-assert the plot armor so the manikin cannot truly die.
_d setVariable ["ACME_MC_arrestElapsed", 0, true];
_d setVariable ["ACME_MC_arrestLast", CBA_missionTime, true];
_d setVariable ["ACME_MC_dying", false, true];

// halt any running deterioration scenario. the pfh runs here, where the manikin is local.
private _scenPFH = _d getVariable ["ACME_MC_scenPFH", -1];
if (_scenPFH >= 0) then { [_scenPFH] call CBA_fnc_removePerFrameHandler; };
_d setVariable ["ACME_MC_scenPFH", -1, false];
_d setVariable ["ACME_MC_scenActive", false, true];
_d setVariable ["ACME_MC_scenName", "", true];

[_d, [["aiUnconsciousness", true, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["instantDeathImmune", true, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["deathBlocked", true, true]]] call ACM_core_fnc_setAceMedicalState;

[_d] call ACME_fnc_megacodeStanceLock;
