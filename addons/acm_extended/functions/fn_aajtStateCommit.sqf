/* Phase 79: authoritative persistent AAJT placement state.
 * _op is one of inguinal, leftarm, rightarm or legs.
 * Placement data is [active, applicationTimeString]. Legs data is an array of limb keys.
 * Transient posture/PFH fields remain owned by the downed worker and are intentionally not handled here.
 */
params ["_patient", "_op", ["_data", []]];
if (isNull _patient) exitWith {};
private _key = toLower _op;
switch (_key) do {
    case "inguinal": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_inguinal", _active, true];
        _patient setVariable ["ACME_AAJT_inguinalAt", if (_active) then {_at} else {nil}, true];
        if (!_active) then {
            _patient setVariable ["ACME_AAJT_legs", [], true];
        };
    };
    case "leftarm": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_axillaleft", _active, true];
        _patient setVariable ["ACME_AAJT_axillaleftAt", if (_active) then {_at} else {nil}, true];
    };
    case "rightarm": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_axillaright", _active, true];
        _patient setVariable ["ACME_AAJT_axillarightAt", if (_active) then {_at} else {nil}, true];
    };
    case "legs": {
        private _legs = _data select {_x in ["leftleg", "rightleg"]};
        _patient setVariable ["ACME_AAJT_legs", _legs arrayIntersect _legs, true];
    };
};
