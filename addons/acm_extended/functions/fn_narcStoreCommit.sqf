/* Phase 87: authoritative writer for the provider's persistent Narc Box syringe/medication store. */
params ["_owner", "_store"];
if (isNull _owner) exitWith {};
_owner setVariable ["ACME_narcStore", _store, true];
