// Explicit callbacks may pass only the medic. ACE end events include context;
// those events must match the action/patient/site that owns the current sound.
private _args = if (_this isEqualType objNull) then {[_this]} else {_this};
_args params ["_medic", ["_patient", objNull], ["_bodyPart", ""], ["_classname", ""]];
if (isNull _medic) exitWith {};
private _state = _medic getVariable ["ACME_wrapSfxState", []];
if (_state isEqualTo []) exitWith {};
_state params ["_token", "_activePatient", "_activePart", "_activeClass"];
if (_classname != "" && {
    !(_patient isEqualTo _activePatient) || {toLower _bodyPart != _activePart} || {toLower _classname != _activeClass}
}) exitWith {};
_medic setVariable ["ACME_wrapSfxState", []];
["ACME_wrapSfx", ["stop", _medic, _activePatient, _token]] call CBA_fnc_serverEvent;

