/* Phase 86: authoritative writer for blood-cooler inventory and coolant state.
 * Publication scope is supplied by the caller to preserve the existing local/public behavior of each path.
 */
params ["_holder", "_field", "_value", ["_public", false]];
if (isNull _holder) exitWith {};
private _name = switch (toLower _field) do {
    case "store": {"ACME_coolerStore"};
    case "coolant": {"ACME_coolerCoolant"};
    default {""};
};
if (_name isEqualTo "") exitWith {};
_holder setVariable [_name, _value, _public];
