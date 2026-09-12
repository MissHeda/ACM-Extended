/* Keep procedural animation/sound; reveal no blockage percentage or diagnosis. */
params ["_medic","_patient",["_bodyPart","body"]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {["ACME_ownerCommand",[_patient,"burp",_this],_patient] call CBA_fnc_targetEvent;};
[_patient,"burp"] call ACME_fnc_ptxTreat;
_patient setVariable ["ACME_CS_lastBurp",CBA_missionTime,true];
[_patient, "burp", "Burped chest seal", [], _medic] call ACME_fnc_chestSealLogOnce;
