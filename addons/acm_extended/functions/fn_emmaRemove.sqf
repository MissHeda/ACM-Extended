// remove the reusable EMMA from the own BVM of the medic and clear any route and display state.
// the inventory item was never consumed.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic"];
if (isNull _medic) exitWith {};

private _wasBvm = _medic getVariable ["ACME_emma_bvmAttached", false];
[_medic] call ACME_fnc_emmaClearIGelForMedic;

_medic setVariable ["ACME_emma_bvmAttached", false, true];
_medic setVariable ["ACME_emma_route", "none", false];
_medic setVariable ["ACME_emma_capPatient", objNull, false];
_medic setVariable ["ACME_emma_lastPatient", objNull, false];
_medic setVariable ["ACME_emma_lastBag", -1e9, false];
_medic setVariable ["ACME_emma_lastContactPatient", objNull, false];
_medic setVariable ["ACME_emma_lastContactTime", -1e9, false];

private _layer = "ACME_EMMA" call BIS_fnc_rscLayer;
_layer cutText ["", "PLAIN"];
uiNamespace setVariable ["ACME_EMMA_DLG", displayNull];

if (_wasBvm) then {
    ["EMMA removed from your BVM.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
