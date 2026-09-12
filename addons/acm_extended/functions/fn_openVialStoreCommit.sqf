/* Phase 88: authoritative writer for open-vial inventory state. */
params ["_holder", "_map"];
if (isNull _holder) exitWith {};
_holder setVariable ["ACME_infusion_openVials", _map, true];
