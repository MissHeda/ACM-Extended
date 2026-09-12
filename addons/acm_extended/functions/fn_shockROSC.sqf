/* Native ROSC transaction, also used for pharmacological termination of pulseless torsades.
   Success must pass native volume/oxygen/reversible-cause checks AND the Extended eligibility gates. */
params ["_patient", ["_epoch", -1]];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {false};
if (_epoch >= 0 && {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {false};
if (!(_patient getVariable ["ace_medical_inCardiacArrest", false])) exitWith {false};
private _result = [_patient] call ACM_circulation_fnc_attemptROSC;
if (_result) then {
    [_patient] call ACME_fnc_rhythmRelease;
    [_patient, 0] call ACME_fnc_rhythmSet;
    [_patient, "ACME_rhythm_torsadesRefractoryUntil", CBA_missionTime + (missionNamespace getVariable ["ACME_rhythm_defibTorsadesRefractorySec", 8])] call ACME_fnc_setVarNet;
};
_result
