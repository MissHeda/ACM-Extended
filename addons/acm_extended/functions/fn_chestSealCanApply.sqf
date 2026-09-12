// Assessment and seal placement remain available on living patients and corpses,
// even without a known chest injury. Inventory/selection checks remain in ACE.
params ["_patient"];
if (isNull _patient) exitWith {false};
(_patient isKindOf "CAManBase")
