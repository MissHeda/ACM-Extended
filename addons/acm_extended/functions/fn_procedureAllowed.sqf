/* B34: live procedure access. Existing equipment/wounds retain their aftercare
   when a mission disables new starts. Skill checks always use ACE's trait reader. */
params [["_medic", objNull, [objNull]], ["_procedure", "", [""]], ["_existing", false, [false]]];
if (isNull _medic || {!alive _medic}) exitWith {false};
private _policy = switch (_procedure) do {
    case "thoracostomy": {["ACME_allowThoracostomy", "ACM_breathing_allowThoracostomy", 1]};
    case "thoracostomySeal": {["", "ACME_skillThoracostomySeal", 1]};
    case "chestTube": {["ACME_allowChestTubes", "ACME_skillChestTube", 2]};
    case "intubation": {["ACME_allowIntubation", "ACME_skillIntubation", 1]};
    case "ventilator": {["ACME_allowVentilator", "ACME_skillVentilator", 1]};
    case "ncd": {["ACME_allowNCD", "ACM_breathing_allowNCD", 1]};
    case "medicationPreparation": {["", "ACME_skillMedicationPreparation", 1]};
    case "pushDoseEpi": {["ACME_allowPushDoseAction", "ACME_skillMedicationBolus", 1]};
    case "htsBolus": {["ACME_allowHTSBolus", "ACME_skillMedicationBolus", 1]};
    default {[]};
};
if (_policy isEqualTo []) exitWith {false};
_policy params ["_enabledKey", "_skillKey", "_defaultSkill"];
if (!_existing && {_enabledKey != ""} && {!(missionNamespace getVariable [_enabledKey, true])}) exitWith {false};
private _skill = missionNamespace getVariable [_skillKey, _defaultSkill];
if !(_skill isEqualType 0) exitWith {false};
// Do not turn a native 'Disabled' or future out-of-range tier into Everyone.
if !(_skill in [0, 1, 2]) exitWith {false};
[_medic, _skill] call ace_medical_treatment_fnc_isMedic
