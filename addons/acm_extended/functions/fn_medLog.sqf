// write a medical log line in the register the descriptor setting asks for.
// call it as [_patient, _type, _plainFormat, _clinicalFormat, _args] call ACME_fnc_medLog.
//
// both format strings take the SAME argument array. SQF's format supports positional %n, so the clinical form
// can reorder without a second array:
//   plain     "%1 began holding direct pressure (%2)"
//   clinical  "Direct pressure, %2, %1"
//   args      [_medicName, _partName]
//
// pass "" as the clinical form for a line that is already written the way a provider would write it. plenty of
// them are: "Calcium chloride %1 g IV" and "Orotracheal intubation: ET tube placed, cuff inflated, airway
// secured" do not get better by being rewritten, and churning them would bury the lines that do.
//
// this also swallows the `if (!isNil "ace_medical_treatment_fnc_addToLog") then {` guard that was copy-pasted
// around roughly seventy call sites. the guard exists because the log function is genuinely absent in some
// load orders, and a missing one returns nil rather than erroring, so the call silently did nothing and the
// guard was the only thing making that visible.
params [["_patient", objNull], ["_type", "activity"], ["_plain", ""], ["_clinical", ""], ["_args", []]];
if (isNil "ace_medical_treatment_fnc_addToLog") exitWith {};
if (isNull _patient) exitWith {};
if (_plain isEqualTo "") exitWith {};

private _fmt = _plain;
if (_clinical isNotEqualTo "" && {((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true)}) then {
    _fmt = _clinical;
};

[_patient, _type, _fmt, _args] call ace_medical_treatment_fnc_addToLog;
