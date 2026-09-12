/* B13 compatibility: never integrate physiology or publish diag_tickTime from a provider. */
params ["_patient", ["_running", false]];
if (!isNull _patient && {_patient == (uiNamespace getVariable ["ACME_laryngo_patient", objNull])}) then {
    [true] call ACME_fnc_suctionPublish;
};
