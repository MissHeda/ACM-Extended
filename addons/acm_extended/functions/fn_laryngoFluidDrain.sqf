/* One actual wand drain / bulb squeeze, not a renderer-timer debit. */
params [["_amount", 1, [0]]];
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (isNull _patient || {!finite _amount} || {_amount <= 0}) exitWith {};
private _epoch = uiNamespace getVariable ["ACME_suctionEpoch", -1];
if (_epoch != ([_patient] call ACME_fnc_clinicalEpoch)) exitWith {};
private _medic = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
private _state = [_patient] call ACME_fnc_laryngoFluidState;
_state params ["_stamp", "_kind", "_remaining"];
if (_kind == "" || {_remaining <= 0}) exitWith {};
[true] call ACME_fnc_suctionPublish;
private _serial = (missionNamespace getVariable ["ACME_laryngoEventSerial", 0]) + 1;
missionNamespace setVariable ["ACME_laryngoEventSerial", _serial];
// Immediate local feedback; the replicated ledger reconciles all viewers afterward.
private _stage = ((uiNamespace getVariable ["ACME_laryngo_fluidStage", 0]) - _amount) max 0;
uiNamespace setVariable ["ACME_laryngo_fluidStage", _stage];
uiNamespace setVariable ["ACME_laryngo_fluidMode", "suction"];
[_patient, "laryngoFluidDrain", [_patient, _medic, _epoch,
    format ["suction:%1:%2", clientOwner, _serial], _stamp, _amount, uiNamespace getVariable ["ACME_suctionToken", ""]]] call ACME_fnc_ownerDispatch;
