// open the blood fridge contents screen.
// call it as [_fridge] call ACME_fnc_bloodFridgeContents.
// the interaction menu could only ever be a list of take actions, which tells a medic nothing until they have
// already committed to opening the door. this is the fridge itself: what is in it, by type, and how long the cold
// chain has left to run.
params ["_fridge"];
if (isNull _fridge) exitWith {};
private _anchor = _fridge getVariable ["ACME_bf_anchor", _fridge];
uiNamespace setVariable ["ACME_bfc_fridge", _anchor];
if !(createDialog "ACME_BloodFridgeContents_Dialog") exitWith {
    ["Could not open the fridge.", 2] call ace_common_fnc_displayTextStructured;
};
