/* Return exact source-solution mL to the invisible partial-vial ledger. No new sealed item is fabricated. */
params [["_holder", objNull, [objNull]], ["_med", "", [""]], ["_ml", 0, [0]], ["_provider", objNull, [objNull]]];
if (isNull _holder || {_med == ""} || {_ml <= 0} || {!finite _ml}) exitWith {false};
// Callers with a captured provider retain that provider across player switching/refund callbacks.
// Legacy three-argument UI callers still use the currently controlled provider.
if (isNull _provider && {hasInterface}) then {_provider = ACE_player;};
private _leaseValid = true;
if (hasInterface && {!isNull _provider} && {_holder isNotEqualTo _provider}) then {
    private _lease = missionNamespace getVariable ["ACME_vialLeaseAccepted", []];
    _leaseValid = _lease isEqualType [] && {count _lease >= 3}
        && {(_lease param [0,objNull]) isEqualTo _holder}
        && {(_lease param [1,""]) != ""}
        && {(_lease param [2,0]) > serverTime};
};
// Exit the function, not just the nested shared-source branch, before any inventory or ledger write.
if (!_leaseValid) exitWith {false};
private _cfg = configFile >> "ACM_Medication" >> "Concentration" >> _med;
if (getNumber (_cfg >> "volume") <= 0) exitWith {false};
private _map = _holder getVariable ["ACME_infusion_openVials", createHashMap];
_map set [_med, ((_map getOrDefault [_med, 0]) max 0) + _ml];
[_holder, _map] call ACME_fnc_openVialStoreCommit;
true
