// suture the placed chest tubes in place. it permanently affixes every side that currently has an unsealed tube, so
// it can no longer be pulled off in the mini-game, and marks the casualty surgical.
// it is per-side, so doing one side then the other and suturing again secures the second tube too. it is called from
// the "Suture Chest Tube" self-action. the incision-close action is separate and still fully closes the
// thoracostomy.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if !([_medic, "thoracostomy", true] call ACME_fnc_procedureAllowed) exitWith {};
if !(([_medic, _patient, ["ACE_surgicalKit"]] call ace_medical_treatment_fnc_hasItem)
    || {_patient getVariable ["ACM_breathing_Thoracostomy_UsedKit", false]}) exitWith {};
private _did = false;
{
    if ((_patient getVariable [format ["ACME_thora_tube_%1", _x], false]) && {!(_patient getVariable [format ["ACME_thora_sealed_%1", _x], false])}) then {
        [_patient, _x, "sealed", true] call ACME_fnc_thoraSideStateCommit;
        [_patient] call ACME_fnc_thoraBumpVer;
        _did = true;
    };
} forEach ["left", "right"];
if (_did) then {
    // a sutured chest tube is a definitive surgical intervention.
    [_patient, true] call ACME_fnc_surgicalCasualtyCommit;
    ["Chest tube sutured in place.", 2] call ace_common_fnc_displayTextStructured;
};
