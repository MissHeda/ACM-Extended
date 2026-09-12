// stage 1 complete: the combat gauze is packed, taking the state from open to packed.
// combat gauze is the first-stage control: a finished packing holds the junction at 50 percent bleed control and
// stays there, and it does not work loose. holding direct pressure on top of the gauze brings it to 100 percent
// control while held. the pressure bandage, the wrap, is the definitive step that makes hemorrhage control
// permanent.
// on a conscious patient the packing hurts, moderately.
params ["_medic", "_patient", "_bodyPart"];
// the packing loop ends with the action rather than running on past it.
[_medic] call ACME_fnc_junctionalPackSfxStop;
private _p = toLower _bodyPart;
_patient setVariable [format ["ACME_Junc_%1", _p], "packed", true];
// the packing is finished, so the hands come off the active-pack tamponade and the finished gauze now controls 50
// percent on its own, handled in the bleed pfh. clear the in-progress flag the bleed pfh watches.
_patient setVariable [format ["ACME_Junc_Packing_%1", _p], false, true];

if (_patient call ace_common_fnc_isAwake) then {
    [_patient, (missionNamespace getVariable ["ACME_junctionalPackPain", 0.2])] call ace_medical_fnc_adjustPainLevel;
};

["Combat gauze packed.", 4] call ace_common_fnc_displayTextStructured;

// record the completed intervention in the activity log of the patient.
[_patient, "activity",
 "%1 packed a junctional wound (%2) with combat gauze",
 "Wound packed, combat gauze, %2, %1",
 [[_medic, false, true] call ace_common_fnc_getName, [_p, "short"] call ACME_fnc_bodyPartName]] call ACME_fnc_medLog;
