// switch the torch through the own function of ACE, so it is the same light, the same state variable and the same
// world proxy the map reads. turn one on here and it is on for the map, and the reverse. one torch.
params [["_class", ""]];
if (!hasInterface) exitWith {};
private _cur = (ACE_player getVariable ["ace_map_flashlight", ["", objNull]]) select 0;
if (_cur isEqualTo _class) then { _class = ""; };  // clicking the lit one turns it off, as ACE's menu does
[ACE_player, _class] call ace_map_fnc_switchFlashlight;
{ if (!isNull _x) then { ctrlDelete _x; }; } forEach (uiNamespace getVariable ["ACME_light_ctrls", []]);
uiNamespace setVariable ["ACME_light_ctrls", []];
