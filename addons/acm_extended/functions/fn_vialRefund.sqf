/* Return exact source-solution mL to the invisible partial-vial ledger. No new sealed item is fabricated. */
params [["_holder", objNull, [objNull]], ["_med", "", [""]], ["_ml", 0, [0]]];
if (isNull _holder || {_med == ""} || {_ml <= 0} || {!finite _ml}) exitWith {false};
private _cfg = configFile >> "ACM_Medication" >> "Concentration" >> _med;
if (getNumber (_cfg >> "volume") <= 0) exitWith {false};
private _map = _holder getVariable ["ACME_infusion_openVials", createHashMap];
_map set [_med, ((_map getOrDefault [_med, 0]) max 0) + _ml];
[_holder, _map] call ACME_fnc_openVialStoreCommit;
true
