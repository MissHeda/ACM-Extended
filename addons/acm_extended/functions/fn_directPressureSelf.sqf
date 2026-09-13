// self direct pressure. hold pressure on any of your own parts without taking ownership of the global continuous-
// action lock. Direct Pressure never issues a weapon-selection command; the player's selected weapon is left alone.
// RMB and esc stop, MMB assesses, and the clinical pressure state remains independent of the selected weapon.
params ["_medic", "_patient", "_bodyPart"];

_medic setVariable ["ACME_DP_Active", true, true];
_medic setVariable ["ACME_DP_Patient", _medic, true];
_medic setVariable ["ACME_DP_Part", _bodyPart];
_medic setVariable ["ACME_DP_Mode", "self"];
_medic setVariable ["ACME_DP_Start", CBA_missionTime];
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 15];
_medic setVariable ["ACME_DP_Paused", false];
_medic setVariable ["ACME_DP_LastPos", getPosASL _medic];

if (dialog) then { closeDialog 0; };

// No medicAnimationPrep here. Self pressure must not trigger a scripted holster/draw cycle before the action begins.

["", "Stop", "Pause / assess"] call ace_interaction_fnc_showMouseHint;
private _ids = [];
_ids pushBack ([0x01, [false,false,false], { [false] call ACME_fnc_directPressureStop; }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF1, [false,false,false], { [false] call ACME_fnc_directPressureStop; true }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_ids pushBack ([0xF2, [false,false,false], { call ACME_fnc_directPressureAssess; }, "keydown", "", false, 0] call CBA_fnc_addKeyHandler);
_medic setVariable ["ACME_DP_KeyIDs", _ids];

[_medic, "activity",
 "%1 started Direct pressure on own %2",
 "%1 started Direct pressure on own %2",
 [[_medic, false, true] call ace_common_fnc_getName, ([_bodyPart, "abbr"] call ACME_fnc_bodyPartName)]] call ACME_fnc_medLog;

private _pfh = [ACME_fnc_directPressureTick, 0, [_medic, _medic, _bodyPart, "self"]] call CBA_fnc_addPerFrameHandler;
_medic setVariable ["ACME_DP_PFH", _pfh];
