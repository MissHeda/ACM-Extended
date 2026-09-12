/*
 * Authoritative ACM Extended mutation gate for ACM's IV-bag map.
 *
 * This deliberately preserves the existing setVariable semantics.  The first fork step is to make every
 * Extended-owned mutation cross one endpoint; owner/epoch validation can then be tightened here without
 * hunting independent writers across infusion, Y-line and transfusion UI code.
 */
params [
    ["_patient", objNull, [objNull]],
    "_bags",
    ["_public", true, [true]]
];

if (isNull _patient) exitWith {false};
[_patient, _bags, _public] call ACM_circulation_fnc_setIVBagsState
