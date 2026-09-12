// ACM mission spawner casualty armor.
// ACM's generatepatient and spawncustompatient create b_survivor_f and strip the gear. a full function override
// breaks across ACM versions, so this addon applies the carrier after the spawn and watches ACM's own
// trainingcasualtygroup. this affects ACM training casualties only. players and normal ai stay untouched.
ACME_acmSpawnerPlateCarrierEnabled = missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierEnabled", true];
ACME_acmSpawnerPlateCarrierClass   = missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierClass", "V_PlateCarrier1_rgr"];

if (isServer && {isNil "ACME_acmSpawnerPlateCarrierPFH"}) then {
    ACME_acmSpawnerPlateCarrierPFH = [{
        if !(missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierEnabled", true]) exitWith {};
        private _grp = missionNamespace getVariable ["ACM_mission_TrainingCasualtyGroup", grpNull];
        if (isNull _grp) exitWith {};
        {
            if !(_x getVariable ["ACME_acmSpawnerPlateCarrierDone", false]) then {
                [_x] call ACME_fnc_acmSpawnerArmor;
            };
        } forEach (units _grp);
    }, 2, []] call CBA_fnc_addPerFrameHandler;
};
