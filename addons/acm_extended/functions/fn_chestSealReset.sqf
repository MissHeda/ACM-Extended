// Full-heal is a new editing epoch. Late intents from the old chest are rejected.
params ["_patient", ["_resetAt", CBA_missionTime]];
if (!isServer || {isNull _patient}) exitWith {};
if (_resetAt < (_patient getVariable ["ACME_NA2_resetServerTime", -1])) exitWith {};
_patient setVariable ["ACME_NA2_resetServerTime", _resetAt, false];
[_patient, "ml", 0, true] call ACME_fnc_thoraOutputStateCommit;
[_patient, "perHour", 0, true] call ACME_fnc_thoraOutputStateCommit;
[_patient, "start", -1, true] call ACME_fnc_thoraOutputStateCommit;
_patient setVariable ["ACME_CS_holeData", [], true];
_patient setVariable ["ACME_CS_wastedData", [], true];
_patient setVariable ["ACME_CS_ncdPlacedSides", [], true];
_patient setVariable ["ACME_CS_penetratingWounds", [], true];
_patient setVariable ["ACME_CS_processedPenetratingCount", 0, true];
_patient setVariable ["ACME_CS_hasPenetratingChestWound", false, true];
_patient setVariable ["ACME_CS_netEpoch", "", false];
_patient setVariable ["ACME_CS_sealRevisions", createHashMap, false];
[_patient, "hist", [], false] call ACME_fnc_thoraOutputStateCommit;
[_patient] call ACME_fnc_chestSealBumpVer;
