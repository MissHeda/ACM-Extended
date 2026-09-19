// Unload covers ESC, another dialog replacing this one, and clinical cancellation.
disableSerialization;
params ["_display"];
{
    _x params ["_emitter","_sound"];
    if (!isNull _sound) then {deleteVehicle _sound;};
    if (!isNull _emitter) then {deleteVehicle _emitter;};
} forEach (_display getVariable ["ACME_stethChannels",[]]);
_display setVariable ["ACME_stethChannels",[]];
_display setVariable ["ACME_stethPressed",false];
if ((uiNamespace getVariable ["ACM_breathing_Stethoscope_DLG",displayNull]) isEqualTo _display) then {
    uiNamespace setVariable ["ACM_breathing_Stethoscope_DLG",displayNull];
    [-1] call ace_hearing_fnc_updateHearingProtection;
};
