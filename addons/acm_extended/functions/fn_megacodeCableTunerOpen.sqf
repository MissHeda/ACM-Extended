// open the live cable tuner for a megacode laptop. it stores the laptop, and its dummy, rope and helpers, so the
// sliders can re-attach the cable and rotate the laptop live.
// _this is [_laptop], from the ACE interaction on the laptop.
params [["_laptop", objNull, [objNull]]];
if !([] call ACME_fnc_debugEnabled) exitWith {};  // debug-gated tuner
if (isNull _laptop) then { _laptop = cursorObject; };
if (isNull _laptop || {!(_laptop getVariable ["ACME_isMegacodeLaptop", false])}) exitWith {
    ["Aim at a megacode laptop to tune its cable.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
};
uiNamespace setVariable ["ACME_MC_CableLaptop", _laptop];
createDialog "ACME_MC_CableTuner";
