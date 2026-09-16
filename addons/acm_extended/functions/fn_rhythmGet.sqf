/* NA3. Pure display/analysis lookup. A custom overlay is valid only while its native contract holds. */
params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {0};
private _raw = [_unit] call ACME_fnc_rhythmNative;
if (!alive _unit) exitWith {_raw};
private _custom = _unit getVariable ["ACME_rhythm_active", 0];
private _arrest = _unit getVariable ["ace_medical_inCardiacArrest", false];
if (_custom in [100,101,102,103,104] && {_raw == 0} && {!_arrest}) exitWith {_custom};
_raw
