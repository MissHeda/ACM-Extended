#include "..\script_component.hpp"
/* One clinical wake request. The normal ACE event runs first. A refused or
 * desynchronized transition is reconciled against its actual CBA state, never
 * against an arbitrary elapsed-time threshold. No delayed worker is created here.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_ignoreKnockOut", false, [false]],
    ["_reason", "clinical", [""]]
];
if (isNull _patient || {!alive _patient} || {!local _patient}
    || {_patient getVariable ["ACME_clinicalRestoring", false]}) exitWith {false};
if !([_patient, _ignoreKnockOut] call FUNC(canWake)) exitWith {false};
if (_ignoreKnockOut && {_patient getVariable [QGVAR(KnockOut_State), false]}) then {
    _patient setVariable [QGVAR(KnockOut_State), false, true];
};
if !([_patient] call FUNC(canWake)) exitWith {false};
[QACEGVAR(medical,WakeUp), _patient] call CBA_fnc_localEvent;
[_patient, _reason] call FUNC(reconcileWake)
