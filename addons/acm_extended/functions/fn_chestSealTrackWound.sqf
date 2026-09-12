// record the exact penetrating chest-wound event that ACM itself processes.
// the ACM_breathing_handleChestInjury arguments are [patient, woundid, wounddamage].
// only wound ids present in ACM_breathing_ChestInjury_Chances are eligible to cause either a pneumothorax or a
// hemothorax, so only those wounds become chest-seal mini-game holes.
params ["_patient", "_woundID", ["_woundDamage", -1]];

if (isNull _patient || {!local _patient}) exitWith {};
if !(_woundID isEqualType 0) exitWith {};

private _injuryMap = missionNamespace getVariable ["ACM_breathing_ChestInjury_Chances", createHashMap];
if !(_woundID in (keys _injuryMap)) exitWith {};

if !(_woundDamage isEqualType 0 && {finite _woundDamage}) then { _woundDamage = -1; };

private _tracked = +(_patient getVariable ["ACME_CS_penetratingWounds", []]);
private _stamp = CBA_missionTime;
if !(_stamp isEqualType 0 && {finite _stamp}) then { _stamp = diag_tickTime; };

_tracked pushBack [_woundID, _woundDamage, _stamp];
_patient setVariable ["ACME_CS_penetratingWounds", _tracked, true];
_patient setVariable ["ACME_CS_hasPenetratingChestWound", true, true];

