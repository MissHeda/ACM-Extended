/*
 * Authoritative mutation gate for medicated infusion-bag state.
 * Bag contents and the derived HasBagMedications flag are committed together so move/remove/rollback paths
 * cannot leave the fast-path flag stale after the final medicated bag disappears.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_entries", [], [[]]],
    ["_public", true, [true]]
];
if (isNull _patient) exitWith {false};
_patient setVariable ["ACME_infusion_BagMedications", _entries, _public];
_patient setVariable ["ACME_infusion_HasBagMedications", !(_entries isEqualTo []), _public];
true
