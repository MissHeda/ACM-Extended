/* New wounds from this native damage application only; never re-roll old injury history. */
params ["_patient", "_newWounds", ["_headDelta", 0]];
if (!local _patient || {!alive _patient}) exitWith {};
if (missionNamespace getVariable ["ACME_sys_tbi", true]) then {[_patient, _newWounds, _headDelta] call ACME_fnc_headInjuryTBI;};
[_patient, _newWounds] call ACME_fnc_junctionalRollSpawn;
[_patient] call ACME_fnc_ownerRegister;
