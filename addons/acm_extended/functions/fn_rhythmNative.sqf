/* NA3. Raw ACM rhythm: use for deterioration/ownership decisions, never the overlay getter. */
params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {0};
_unit getVariable ["ACM_circulation_Cardiac_RhythmState", 0]
