// this runs where the dummy is local. it wipes all damage and open and bandaged wounds and restores the baseline
// blood and pain, then re-settles the lying pose.
params ["_d"];
if (isNull _d || {!local _d}) exitWith {};
_d setDamage 0;
{ _d setHitPointDamage [_x, 0]; } forEach ((getAllHitPointsDamage _d) param [0, []]);
[_d, [["openWounds", createHashMap, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["bandagedWounds", createHashMap, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["stitchedWounds", createHashMap, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["pain", 0, true]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["bloodVolume", 6.0, true]]] call ACM_core_fnc_setAceMedicalState;
// clear any junctional, axilla and inguinal, wounds so the bleed of the manikin stops and the 2-per-region cap
// resets.
{ _d setVariable [format ["ACME_Junc_%1", _x], "", true]; } forEach ["leftarm", "rightarm", "leftleg", "rightleg"];
// the component prefix was wrong, so the isnil guard was always true and this silently never ran. the manikin kept
// bleeding from wounds that had just been cleared, until something else happened to recompute it.
// it lives in medical_status, not medical.
if (!isNil "ace_medical_status_fnc_updateWoundBloodLoss") then { [_d] call ace_medical_status_fnc_updateWoundBloodLoss; };
[_d] call ACME_fnc_megacodeStanceLock;
