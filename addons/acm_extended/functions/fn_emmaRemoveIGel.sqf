// Remove the patient-side EMMA from an ET tube or i-gel, leaving the medic's BVM route alone.
// the inventory item was never consumed, so this only clears the patient-side route and display state.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params [["_medic", objNull], ["_patient", objNull]];

if (isNull _medic || {isNull _patient}) exitWith {};
private _airway = [_patient] call ACME_fnc_emmaAirwayKind;
private _name = switch (_airway) do {case "ett": {"ET tube"}; case "igel": {"i-gel"}; default {"airway"};};

if !(_patient getVariable ["ACME_emma_igelAttached", false]) exitWith {
    ["No EMMA is attached to this patient.", 2, _medic] call ace_common_fnc_displayTextStructured;
};

[_patient, false] call ACME_fnc_emmaIGelStateCommit;

// clear only the patient-side capture of the local medic, if it was pointed at this patient. do not clear
// ACME_emma_bvmAttached, because removing an i-gel EMMA should not detach the EMMA from the own BVM of the
// medic.
if ((_medic getVariable ["ACME_emma_lastContactPatient", objNull]) isEqualTo _patient) then {
    _medic setVariable ["ACME_emma_route", "none", false];
    _medic setVariable ["ACME_emma_capPatient", objNull, false];
    _medic setVariable ["ACME_emma_lastPatient", objNull, false];
    _medic setVariable ["ACME_emma_lastBag", -1e9, false];
    _medic setVariable ["ACME_emma_lastContactPatient", objNull, false];
    _medic setVariable ["ACME_emma_lastContactTime", -1e9, false];
};

private _layer = "ACME_EMMA" call BIS_fnc_rscLayer;
_layer cutText ["", "PLAIN"];
uiNamespace setVariable ["ACME_EMMA_DLG", displayNull];

[format ["EMMA removed from their %1.", _name], 2, _medic] call ace_common_fnc_displayTextStructured;
