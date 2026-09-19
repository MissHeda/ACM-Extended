/* NA2: explicit patient-owner commands; never accept arbitrary code/function names.
   Called by CBA in an unscheduled scope. A locality change in transit is rerouted. */
params ["_patient", "_operation", ["_args", []], ["_hops", 0]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    if (_hops < 4) then {
        ["ACME_ownerCommand", [_patient, _operation, _args, _hops + 1], _patient] call CBA_fnc_targetEvent;
    } else {  };
};
switch (_operation) do {
    case "stethoscopeLungs": {
        _args params [["_epoch",-1]];
        if (alive _patient && {_epoch == ([_patient] call ACME_fnc_clinicalEpoch)}
            && {CBA_missionTime >= (_patient getVariable ["ACME_stethNextLungUpdate",-1])}) then {
            _patient setVariable ["ACME_stethNextLungUpdate",CBA_missionTime + 0.5];
            [_patient] call ACM_breathing_fnc_updateLungState;
        };
    };
    case "suctionState": {_args call ACME_fnc_suctionStateLocal;};
    case "ecgJostle": {_args call ACME_fnc_ecgJostleLocal;};
    case "medicationLine": {_args call ACME_fnc_medicationLineLocal;};
    // Small non-bag crystalloid boluses still contribute real circulating volume. Route the mutation through
    // the casualty owner so it cannot race the native circulation integrator on another machine.
    case "crystalloidCredit": {
        _args params [["_liters", 0, [0]]];
        if (finite _liters && {_liters > 0}) then {
            [_patient, [["salineVolume", (_patient getVariable ["ACM_circulation_Saline_Volume", 0]) + _liters]], true] call ACM_circulation_fnc_setRuntimeState;
        };
    };
    case "headElevHoldStart": {_args call ACME_fnc_headElevHoldStart;};
    case "headElevHoldRelease": {_args call ACME_fnc_headElevHoldRelease;};
    case "headElevHoldStop": {_args call ACME_fnc_headElevHoldStop;};
    case "headElevTreatment": {_args call ACME_fnc_headElevTreatmentEvent;};
    case "chestAccessVestEvent": {_args call ACME_fnc_chestAccessVestEvent;};
    case "headElevTilt": {_args call ACME_fnc_headElevApplyTilt;};
    case "headElevCollision": {_args call ACME_fnc_headElevCollision;};
    case "headElevSuspend": {_args call ACME_fnc_headElevSuspend;};
    case "headElevTryResume": {_args call ACME_fnc_headElevTryResume;};
    case "headElevResume": {[_patient] call ACME_fnc_headElevResume;};
    case "headElevStart": {_args call ACME_fnc_headElevateStart;};
    case "headElevStop": {_args call ACME_fnc_headElevateStop;};
    case "headElevDeath": {[_patient] call ACME_fnc_headElevDeathRelease;};
    case "headElevMedicStart": {_args call ACME_fnc_headElevMedicStart;};
    case "headElevMedicSeq": {_args call ACME_fnc_headElevMedicSeq;};
    case "laryngoFluidDrain": {_args call ACME_fnc_laryngoFluidDrainLocal;};
    case "laryngoConsequence": {_args call ACME_fnc_laryngoConsequenceLocal;};
    case "laryngoStimulus": {_args call ACME_fnc_laryngoStimulusLocal;};
    case "infusionClamp": {_args call ACME_fnc_infusionClampLocal;};
    case "pressureCuff": {_args call ACME_fnc_pressureInfuserCommit;};
    case "ivState": {_args call ACME_fnc_ivStateLocal;};
    case "ivSite": {_args call ACME_fnc_ivPlacementLocal;};
    case "preparedAttach": {_args call ACME_fnc_preparedAttachLocal;};
    case "arrest": {_args call ACME_fnc_arrestLocal;};
    case "rhythmSet": {_args call ACME_fnc_rhythmSet;};
    case "rhythmToggle": {_args call ACME_fnc_rhythmToggle;};
    case "shock": {_args call ACME_fnc_shockLocal;};
    case "aajtFlow": {_args call ACME_fnc_aajtSetLegTQ;};
    case "junctionalInflict": {_args call ACME_fnc_junctionalInflict;};
    case "junctional": {_args call ACME_fnc_junctionalResume;};
    case "restore": {_args call ACME_fnc_clinicalRestore;};
    case "infusionRegister": {_args call ACME_fnc_infusionRegisterLocal;};
    case "infusionRemove": {_args call ACME_fnc_infusionRemoveLocal;};
    case "yFlush": {_args call ACME_fnc_yFlushStart;};
    case "bagMove": {_args call ACME_fnc_clinicalBagMove;};
    case "register": { [_patient] call ACME_fnc_ownerRegister; };
    case "hpmkWrap": { _args call ACME_fnc_hpmkWrap; };
    case "hpmkRemove": { _args call ACME_fnc_hpmkRemove; };
    case "autoBP": { _args call ACME_fnc_toggleAutoBP; };
    case "cheyne": { _args call ACME_fnc_debugCheyneStokes; };
    case "debugSeizure": { _args call ACME_fnc_debugInduceSeizure; };
    case "tbiInit": { _args call ACME_fnc_tbiInit; };
    case "thoraDrain": { [_patient] call ACME_fnc_thoraPassiveDrain; };
    case "thoraAftercare": {_args call ACME_fnc_thoraAftercareLocal;};
    case "nrbState": { _args call ACME_fnc_nrbStateLocal; };
    case "nrbAck": { _args call ACME_fnc_nrbOxygenAck; };
    case "chestEffect": { _args call ACME_fnc_chestSealEffectLocal; };
    case "chestSealBurpGesture": {
        _args params ["_medic","_casualty"];
        if (_medic isEqualTo _patient && {!isNull _casualty} && {alive _medic}
            && {!(_medic getVariable ["ACE_isUnconscious",false])}
            && {(_medic distance _casualty) <= 5}) then {
            [_medic,"chestSeal",3] call ACME_fnc_treatmentGesture;
        };
    };
    case "burp": { _args call ACME_fnc_chestSealBurp; };
    case "chestSealRoll": {_args call ACME_fnc_chestSealRoll;};
    case "chestSealPatientBegin": {_args call ACME_fnc_chestSealPatientBegin;};
    case "chestSealPatientEnd": {_args call ACME_fnc_chestSealPatientEnd;};
    case "patientAnimRequest": {_args call ACME_fnc_patientAnimRequest;};
    case "patientAnimRelease": {_args call ACME_fnc_patientAnimRelease;};
    case "treatmentPatientSettle": {_args call ACME_fnc_treatmentPatientSettle;};
};
