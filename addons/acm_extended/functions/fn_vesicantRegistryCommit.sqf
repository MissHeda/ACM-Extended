/* Phase 83: authoritative writer for vesicant patient registry metadata.
 * Operations: records => replace per-patient exposure-key registry; dirty => publish dirty flag.
 */
params ["_patient", "_op", ["_data", nil]];
if (isNull _patient) exitWith {};
switch (toLower _op) do {
    case "records": { _patient setVariable ["ACME_vesicant_records", _data, true]; };
    case "dirty": { _patient setVariable ["ACME_vesicant_patients_dirty", _data, false]; };
};
