// B70 restore the elevated animation after a maneuver, provided elevation was not canceled. No casualty attach/setPos is used.
// the arg is [_patient].
params ["_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevResume", [_patient]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};  // canceled -> never restore
if !(_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {};
_patient setVariable ["ACME_headElev_Suspended", false, true];
_patient setVariable ["ACME_headElev_basePosASL", getPosASL _patient, true];
_patient setVariable ["ACME_headElev_baseDir", getDir _patient, true];
// Pick the visual bolster back up and replay the authored patient grab animation. The casualty itself is never attached.
[_patient] call ACME_fnc_headElevPropApply;
[_patient] call ACME_fnc_headElevApplyTilt;
