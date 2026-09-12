/* Acknowledgements route to the supplier's CURRENT owner, including disconnected AI.
   Remove escrow before inventory changes so repeated replies cannot duplicate items. */
params ["_medic","_id","_accepted",["_reason",""]];
if (isNull _medic) exitWith {};
if (!local _medic) exitWith {["ACME_medicationAck",_this,_medic] call CBA_fnc_targetEvent;};
private _escrow = _medic getVariable ["ACME_medicationEscrow",createHashMap];
private _row = _escrow getOrDefault [_id,[]];
if (_row isEqualTo []) exitWith {};
_escrow deleteAt _id;
[_medic, _escrow] call ACME_fnc_medicationEscrowCommit;
[_medic,_row select 2,_accepted] call ACME_fnc_medicationRefund;
// B18: acknowledgements are intentionally silent. Rejected requests still refund the escrowed inventory;
// the transport/ownership layer does not coach the provider with transaction-status helper text.
if (hasInterface && {_medic == ACE_player}) then {
    if (!isNull findDisplay 84000) then {call ACME_fnc_skRefreshDrawn;call ACME_fnc_skBuildHotspots;};
};
