// stage 2 complete: the pressure bandage is applied, taking the state from packed to wrapped.
// this is the hemorrhage-control step: the arterial drain stops, because the bleed pfh sees wrapped and excludes the
// part, and we clot the underlying ACE wound to secure hemostasis. it plays the tie-off sfx and stops the wrap
// loop. on a conscious patient the wrap hurts, moderately, and the pack plus wrap total stays below the maximum of
// a tourniquet.
params ["_medic", "_patient", "_bodyPart"];
private _p = toLower _bodyPart;
_patient setVariable [format ["ACME_Junc_%1", _p], "wrapped", true];
// secured: cancel the fall-off clock, so it cannot trip after the wrap.
_patient setVariable [format ["ACME_Junc_PackedAt_%1", _p], -1, true];

// stop the wrap-sfx loop and always play the tie-off when the timer completes.
[_medic] call ACME_fnc_junctionalWrapSfxStop;
if (!isNull _medic) then { [_medic, "ACME_JunctionalTie"] remoteExec ["ACME_fnc_remoteSay3D", 0]; };

// secure hemostasis on the underlying wound: clot up to 5 wounds, at severity 4 or below, stable.
if (!isNil "ACM_damage_fnc_clotWoundsOnBodyPart") then {
    [_patient, _p, 5, 4, false] call ACM_damage_fnc_clotWoundsOnBodyPart;
};

if (_patient call ace_common_fnc_isAwake) then {
    [_patient, (missionNamespace getVariable ["ACME_junctionalWrapPain", 0.2])] call ace_medical_fnc_adjustPainLevel;
};

["Pressure bandage secured. junctional hemorrhage controlled.", 3] call ace_common_fnc_displayTextStructured;

// record the completed intervention in the activity log of the patient.
[_patient, "activity",
 "%1 controlled a junctional wound (%2) with a pressure bandage",
 "Hemorrhage controlled, pressure dressing, %2, %1",
 [[_medic, false, true] call ace_common_fnc_getName, [_p, "short"] call ACME_fnc_bodyPartName]] call ACME_fnc_medLog;
