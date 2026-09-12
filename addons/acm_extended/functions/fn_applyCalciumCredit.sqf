params ["_patient", "_medication", ["_doseMg", 0]];
if (isNull _patient || {_doseMg <= 0}) exitWith {0};

private _map = missionNamespace getVariable ["ACME_infusion_calciumCaCl2Equivalent", createHashMapFromArray []];
private _equiv = _map getOrDefault [_medication, -1];
if (_equiv < 0) exitWith {0};

private _gramsEq = ((_doseMg max 0) / 1000) * _equiv;
if (_gramsEq <= 0) exitWith {0};

// Native ACM only dispatches its calcium callback for chloride. Forward gluconate once,
// using the same equivalent mass as the Extended citrate/hypocalcemia model.
if (_medication == "CalciumGluconate_IV") then {
    [_patient, "", "CalciumChloride_IV", _gramsEq * 1000] call ACM_circulation_fnc_handleMed_CalciumChlorideLocal;
};
private _given = [_patient, _gramsEq, "add", true, false] call ACME_fnc_calciumCreditCommit;

if (!isNil "ACME_circ_activePatients") then {
    ACME_circ_activePatients pushBackUnique _patient;
};

_gramsEq
