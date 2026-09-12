/* Read the active goggle provider. Never synthesize a mask or turn shader
   coefficients into an RGB tint. Private modelOptics remains engine-owned. */
params [["_medic", objNull, [objNull]]];
if (isNull _medic) exitWith {["", displayNull, false]};
private _goggles = hmd _medic;
private _live = uiNamespace getVariable ["ace_nightvision_titleDisplay", displayNull];
private _cfg = configFile >> "CfgWeapons" >> _goggles;
private _liveHMD = missionNamespace getVariable ["ace_nightvision_playerHMD", ""];

private _native2D = _goggles != "" && {_liveHMD == _goggles} && {currentVisionMode _medic == 1}
    && {getText (_cfg >> "modelOptics") == ""}
    && {missionNamespace getVariable ["ace_nightvision_running", false]}
    && {(missionNamespace getVariable ["ace_nightvision_effectScaling", 0]) > 0}
    && {!isNull _live}
    && {isClass (configFile >> "RscTitles" >> "ace_nightvision_title")}
    && {!isNil "ace_nightvision_fnc_refreshGoggleType"};
[_goggles, _live, _native2D]
