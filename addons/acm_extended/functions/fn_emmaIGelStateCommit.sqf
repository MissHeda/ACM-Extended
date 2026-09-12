/* Phase 89: authoritative writer for EMMA-to-i-gel attachment identity state. */
params ["_patient", "_attached", ["_time", nil], ["_uid", nil], ["_name", nil]];
if (isNull _patient) exitWith {};
_patient setVariable ["ACME_emma_igelAttached", _attached, true];
_patient setVariable ["ACME_emma_igelAttachedTime", if (_attached) then {_time} else {nil}, true];
_patient setVariable ["ACME_emma_igelAttachedByUID", if (_attached) then {_uid} else {nil}, true];
_patient setVariable ["ACME_emma_igelAttachedByName", if (_attached) then {_name} else {nil}, true];
