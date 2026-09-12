/* Phase 81: authoritative writer for pressure-infuser fitted-cuff and request-receipt state. */
params ["_patient", "_op", ["_data", nil]];
if (isNull _patient) exitWith {};
switch (toLower _op) do {
    case "cuffs": { _patient setVariable ["ACME_piCuffs", _data, true]; };
    case "receipts": { _patient setVariable ["ACME_piReceipts", _data, true]; };
};
