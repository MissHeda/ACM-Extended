// a wrapper for the measure blood pressure of ACM. see the notes below.
// the manual bp of ACM runs through begincontinuousaction, which begins with an exitwith on continuousaction_active.
// holding torso direct pressure keeps that flag true, so we release dp first, and ACE reopens the medical menu on
// treatment success, so we open the cuff on the next frame after that settles.
// directPressureStop reads ACE_player as the medic, which is this same player.
params ["_medic", "_patient", "_bodyPart", ["_stethoscope", false]];

if (isNull _patient) exitWith { };

private _releasedTorso = (_medic getVariable ["ACME_DP_Active", false])
    && {(_medic getVariable ["ACME_DP_Mode", ""]) == "torso"};
if (_releasedTorso) then {[false] call ACME_fnc_directPressureStop;};

[{
    params ["_medic", "_patient", "_bodyPart", "_stethoscope", "_releasedTorso"];
    if (isNull _patient) exitWith {};
    // Only the torso direct-pressure maneuver needed the continuous-action lock released. Never clear another
    // maneuver merely because one-handed head/limb pressure happens to be active.
    if (_releasedTorso) then {[false] call ACM_core_fnc_setContinuousActionActive;};
    if (isNil "ACM_circulation_fnc_measureBP") exitWith {};
    [_medic, _patient, _bodyPart, _stethoscope] call ACM_circulation_fnc_measureBP;
}, [_medic, _patient, _bodyPart, _stethoscope, _releasedTorso]] call CBA_fnc_execNextFrame;
