// ACM manual BP enters its own continuous-action phase after the ACE treatment completes. Direct Pressure no
// longer owns ACM's global continuous-action gate, so BP can start normally. The shared DP tick sees the BP
// continuous maneuver, suspends the pressure marker/pose for its duration, and automatically resumes afterward.
params ["_medic", "_patient", "_bodyPart", ["_stethoscope", false]];

if (isNull _patient || {isNull _medic}) exitWith {};

[{
    params ["_medic", "_patient", "_bodyPart", "_stethoscope"];
    if (isNull _patient || {isNull _medic}) exitWith {};
    if (isNil "ACM_circulation_fnc_measureBP") exitWith {};
    [_medic, _patient, _bodyPart, _stethoscope] call ACM_circulation_fnc_measureBP;
}, [_medic, _patient, _bodyPart, _stethoscope]] call CBA_fnc_execNextFrame;
