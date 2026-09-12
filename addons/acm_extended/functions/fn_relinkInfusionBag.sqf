/* NA3: native move completion is an identified owner transaction. Never bind to a same-looking bag. */
params ["_patient", "_uid"];
private _entry = (_patient getVariable ["ACME_infusion_BagMedications", []]) select {(_x param [0, ""]) == _uid};
if (hasInterface) then {call ACME_fnc_updateTransfusionControls;};
!(_entry isEqualTo [])
