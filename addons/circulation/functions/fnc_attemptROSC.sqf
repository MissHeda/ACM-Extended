#include "..\script_component.hpp"
/*
    B67 single ROSC transaction.

    This is the compile-time ACM_circulation_fnc_attemptROSC override. All native ACM callers, ACME defibrillation,
    reversible PEA and medication conversion therefore enter the same gate. The actual successful transition is
    intentionally the native ACM transaction: CPRSucceeded is still what leaves cardiac arrest.
*/
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {false};

private _eligibility = [_patient, true] call FUNC(roscEligibility);
_eligibility params ["_eligible", ["_reason", ""]];

if (!(IN_CRDC_ARRST(_patient)) || {!(alive _patient)}) exitWith {false};

if (_eligible) exitWith {
    [QACEGVAR(medical,CPRSucceeded), _patient] call CBA_fnc_localEvent;
    if (GVAR(Hardcore_PostCardiacArrest)) then {
        _patient setVariable [QGVAR(Hardcore_PostCardiacArrest), true, true];
    };
    _patient setVariable [QGVAR(CardiacArrest_Time), nil, true];
    _patient setVariable ["ACME_rosc_lastBlockedReason", "", false];
    true
};

_patient setVariable ["ACME_rosc_lastBlockedReason", _reason, false];
[QGVAR(handleReversibleCardiacArrest), _patient] call CBA_fnc_localEvent;
false
