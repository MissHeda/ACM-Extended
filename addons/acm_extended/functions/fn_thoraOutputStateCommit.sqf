/* Phase 85: authoritative writer for thoracostomy drainage/output metrics.
 * _public is preserved per caller because live totals are networked while high-frequency history/fluid cursors are local.
 */
params ["_patient", "_field", ["_value", nil], ["_public", true]];
if (isNull _patient) exitWith {};
private _key = toLower _field;
private _name = switch (_key) do {
    case "ml": {"ACME_thora_outputMl"};
    case "perhour": {"ACME_thora_outputPerHour"};
    case "start": {"ACME_thora_outputStart"};
    case "hist": {"ACME_thora_outputHist"};
    case "fluidseen": {"ACME_thora_fluidSeen"};
    default {""};
};
if (_name isEqualTo "") exitWith {};
_patient setVariable [_name, _value, _public];
