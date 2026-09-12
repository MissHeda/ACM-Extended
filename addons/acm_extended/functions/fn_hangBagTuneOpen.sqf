if !([] call ACME_fnc_debugEnabled) exitWith {};
if !(ACE_player getVariable ["ACME_hang_Active", false]) exitWith {
    ["Raise a bag before opening the placement tuner.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
};
createDialog "ACME_HangBag_Tuner";
