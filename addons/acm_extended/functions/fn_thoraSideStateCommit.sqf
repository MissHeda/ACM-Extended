/* Phase 84: authoritative writer for durable per-side thoracostomy procedural state. */
params ["_patient", "_side", "_field", ["_value", nil]];
if (isNull _patient) exitWith {};
_side = toLower _side;
_field = toLower _field;
if !(_side in ["left","right"]) exitWith {};
private _allowed = ["incision","incisionscore","prep","infection","open","ribtarget","site","tube","sealed"];
if !(_field in _allowed) exitWith {};
_patient setVariable [format ["ACME_thora_%1_%2", _field, _side], _value, true];
