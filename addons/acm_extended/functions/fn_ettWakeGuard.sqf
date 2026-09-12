/* B14: ETT intolerance is observable, not an automatic unconsciousness/extubation rule.
   Existing vent/capnography cough/distress readers respond to inadequate sedation.
   No recurring "five seconds then unconscious" loop for AI or players. */
params ["_patient"];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
private _intolerant = _patient getVariable ["ACME_ETT_Inserted", false]
    && {!(_patient getVariable ["ace_medical_inCardiacArrest", false])}
    && {!(_patient getVariable ["ACME_roc_paralyzed", false])}
    && {!(_patient getVariable ["ACE_isUnconscious", false])}
    && {([_patient] call ACME_fnc_sedationOnBoard) < (call ACME_fnc_sedationThreshold)};
private _old = _patient getVariable ["ACME_ettIntolerant", false];
[_patient, "ACME_ettIntolerant", _intolerant] call ACME_fnc_setVarNet;
if (_intolerant && {!_old}) then {
    [_patient, "activity", "Awake and not tolerating the ET tube; reassess sedation and airway.", []] call ace_medical_treatment_fnc_addToLog;
};
