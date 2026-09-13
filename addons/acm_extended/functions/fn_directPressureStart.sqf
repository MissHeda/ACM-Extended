// the direct pressure entry. the torso is a two-handed active maneuver, in the frozen CPR pose with mouse-button
// controls, and every other part, the head and limbs, is a one-handed crouch-and-hold bound to the patient on a
// short leash. both clot wounds on the held part, with a very high chance once held past 15 s.
// the ACE treatment callback args are [_medic, _patient, _bodyPart], where _bodyPart is lowercase.
params ["_medic", "_patient", ["_bodyPart", ""]];
_bodyPart = toLower _bodyPart;
if (isNull _patient) exitWith {};

if (_medic getVariable ["ACME_DP_Active", false]) exitWith {
    ["You're already holding direct pressure.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
// Clear any stale PFH/key/patient markers left by an interrupted prior hold before starting a new one.
[true, _medic] call ACME_fnc_directPressureStop;

// mark this part as actively under direct pressure, read by the junctional bleed to partially control it. it is
// globally synced so the machine of the casualty, where the bleed pfh runs, sees it. it is cleared in stop.
_patient setVariable [format ["ACME_DP_press_%1", _bodyPart], _medic, true];

// Torso pressure uses the stronger two-handed pose, but direct pressure is not an exclusive continuous-action lock.
// Providers must still be able to open the medical menu, stop pressure explicitly, and perform another intervention.
if (_bodyPart == "body") then {
    [_medic, _patient, _bodyPart] call ACME_fnc_directPressureTorso;
} else {
    if (_patient isEqualTo _medic) then {
        [_medic, _patient, _bodyPart] call ACME_fnc_directPressureSelf;
    } else {
        [_medic, _patient, _bodyPart] call ACME_fnc_directPressureLimb;
    };
};
