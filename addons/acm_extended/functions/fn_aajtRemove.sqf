// remove a NAR AAJT-s from the placement the action was used on, where body is inguinal and LeftArm or RightArm is
// the axilla.
// an inguinal removal pulls exactly the tourniquets the device applied, tracked in ACME_AAJT_legs, rather than any
// manual tq the medic placed separately. it then restarts the junctional bleed, so any still-open junction
// resumes draining.
// _this is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
private _p = toLower _bodyPart;

switch (_p) do {
    case "leftleg";
    case "rightleg": {
        [_patient, "inguinal", [false]] call ACME_fnc_aajtStateCommit;
        { [_patient, _x, false] call ACME_fnc_aajtSetLegTQ; } forEach (_patient getVariable ["ACME_AAJT_legs", []]);
        // the legs have blood in them again, so the casualty can stand. the watcher sees the cleared inguinal
        // flag on its next pass and stops itself, which also releases the input lock.
        _patient setVariable ["ACME_AAJT_downedAt", -1];
        [_patient, "legs", []] call ACME_fnc_aajtStateCommit;
        ["AAJT-S removed (inguinal).", 2.5] call ace_common_fnc_displayTextStructured;
    };
    case "leftarm":  { [_patient, "leftarm", [false]] call ACME_fnc_aajtStateCommit; ["AAJT-S removed (left axilla).", 2.5] call ace_common_fnc_displayTextStructured; };
    case "rightarm": { [_patient, "rightarm", [false]] call ACME_fnc_aajtStateCommit; ["AAJT-S removed (right axilla).", 2.5] call ace_common_fnc_displayTextStructured; };
    default {};
};

// a junction that was held by the device may resume bleeding, so restart the drain. it is idempotent and routes to
// the machine of the patient, and if every junction is still controlled it simply exits again on its own.
[_patient] call ACME_fnc_junctionalStartBleed;

// it is a reusable device: hand the AAJT-s back to the medic who took it off, because it was consumed onto the
// patient when applied. if the medic has no room, drop it at their feet so it is never lost.
if (!isNull _medic) then {
    if (_medic canAdd "ACME_AAJT_S") then {
        _medic addItem "ACME_AAJT_S";
    } else {
        private _wh = createVehicle ["GroundWeaponHolder", getPosATL _medic, [], 0.5, "CAN_COLLIDE"];
        _wh addItemCargoGlobal ["ACME_AAJT_S", 1];
    };
};

// record the completed intervention in the activity log of the patient.
[_patient, "activity", "%1 removed an AAJT-S", [[_medic, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
