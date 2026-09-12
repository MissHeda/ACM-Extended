/* Exact mass enters a short distribution/delivery queue. No source-volume inference.
   Native kinetics own therapeutic effect. This queue supplies custom rate/toxicity models.
   Infusions call this at fluidCommit, NOT again when accumulated native pulses are emitted. */
params ["_patient","_class","_amount","_seconds"];
if (isNull _patient || {!local _patient} || {_amount <= 0} || {!finite _amount}) exitWith {};
private _base = (_class splitString "_") select 0;
private _tracked = _base in ["Epinephrine","Norepinephrine","Amiodarone","CalciumChloride","CalciumGluconate","Magnesium","Lidocaine","Esmolol"]
    || {_base in (missionNamespace getVariable ["ACME_infusion_pk",createHashMap])};
if (!_tracked) exitWith {};
// Manual epinephrine already owns a separate finite reserve; no duplicate rate support.
if (_base == "Epinephrine" && {!(missionNamespace getVariable ["ACME_driveIsInfusion",false])}) exitWith {};
_seconds = _seconds max 0.25;
private _queue = _patient getVariable ["ACME_medicationDriveQueue",[]];
_queue pushBack [_base,_amount,_seconds];
_patient setVariable ["ACME_medicationDriveQueue",_queue,true];
