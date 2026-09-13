/* Remove the AAJT-S placement addressed by the selected body part. */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
private _p = toLowerANSI _bodyPart;
private _removed = false;
switch (_p) do {
    case "body": {
        if (_patient getVariable ["ACME_AAJT_zone3", false]) then {
            [_patient, "zone3", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "leftleg", false] call ACME_fnc_aajtSetLegTQ;
            [_patient, "rightleg", false] call ACME_fnc_aajtSetLegTQ;
            [_patient] call ACME_fnc_aajtDownedStop;
            _removed = true;
            ["AAJT-S removed (Zone 3 REBOA).", 2.5] call ace_common_fnc_displayTextStructured;
        };
    };
    case "leftleg";
    case "rightleg": {
        if ((_patient getVariable ["ACME_AAJT_inguinal", false]) && {(_patient getVariable ["ACME_AAJT_inguinalSide", ""]) == _p}) then {
            [_patient, "inguinal", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, _p, false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            ["AAJT-S removed (inguinal).", 2.5] call ace_common_fnc_displayTextStructured;
        };
    };
    case "leftarm": {
        if (_patient getVariable ["ACME_AAJT_axillaleft", false]) then {
            [_patient, "leftarm", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "leftarm", false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            ["AAJT-S removed (left axilla).", 2.5] call ace_common_fnc_displayTextStructured;
        };
    };
    case "rightarm": {
        if (_patient getVariable ["ACME_AAJT_axillaright", false]) then {
            [_patient, "rightarm", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "rightarm", false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            ["AAJT-S removed (right axilla).", 2.5] call ace_common_fnc_displayTextStructured;
        };
    };
    default {};
};
if (!_removed) exitWith {};
[_patient] call ACME_fnc_junctionalStartBleed;
if (!isNull _medic) then {
    if (_medic canAdd "ACME_AAJT_S") then {_medic addItem "ACME_AAJT_S";} else {
        private _wh = createVehicle ["GroundWeaponHolder", getPosATL _medic, [], 0.5, "CAN_COLLIDE"];
        _wh addItemCargoGlobal ["ACME_AAJT_S", 1];
    };
};
[_patient, "activity", "%1 removed an AAJT-S", [[_medic, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
