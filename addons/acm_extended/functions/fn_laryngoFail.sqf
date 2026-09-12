/* Failed placement is recoverable. No automatic anatomy-grade escalation or mouthful. */
params ["_patient", ["_reason", "unknown"]];
if (isNull _patient) exitWith {};
if (_reason in ["miss", "gag", "blocked", "esophageal"]) then {
    if (uiNamespace getVariable ["ACME_laryngo_missLatched", false]) then {_reason = "alreadyCounted";} else {
        uiNamespace setVariable ["ACME_laryngo_missLatched", true];
    };
};
if (_reason != "alreadyCounted") then {[_patient, _reason] call ACME_fnc_laryngoConsequence;};
