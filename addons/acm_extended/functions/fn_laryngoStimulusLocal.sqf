/* One owner event starts the transient response. Repeated reads never add another surge. */
params ["_patient", "_medic", "_epoch", "_id"];
if (!local _patient) exitWith {[_patient, "laryngoStimulus", _this] call ACME_fnc_ownerDispatch;};
if (!alive _patient || {isNull _medic} || {!alive _medic} || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {};
if (_medic distance _patient > 5 && {isNull objectParent _medic || {objectParent _medic != objectParent _patient}}) exitWith {};
if ((_patient getVariable ["ACME_laryngoStimulusId", ""]) == _id) exitWith {};
_patient setVariable ["ACME_laryngoStimulusId", _id, true];
private _previous = _patient getVariable ["ACME_laryngoStimulusAt", -1];
// Regripping during one response cannot stack another stimulus or another ICP dose.
if (_previous >= 0 && {CBA_missionTime - _previous < 60}) exitWith {};
private _blunt = [_patient] call ACME_fnc_fentanylOnBoard;
_patient setVariable ["ACME_laryngoStimulusAt", CBA_missionTime, true];
_patient setVariable ["ACME_laryngoStimulusStrength", 1 - _blunt, true];
// TBI applies a separately tracked transient contribution in fn_tbiHandle.
// Never add a permanent ICP step on each blade pickup.
// This stimulus has no automatic provider-facing result. Assess the patient.
