// vomiting with an OPA in spits it out.
// call it as [_patient] call ACME_fnc_airwayVomitOPA, from fn_circhandle.
// an oropharyngeal airway sits loose in the mouth, held there by nothing but the shape of the airway, so a casualty
// who vomits ejects it. once it has been in a mouth full of stomach contents it is not going back in, so the item
// is destroyed rather than returned.
// an NPA is not affected, because it is anchored through the nose. neither is an SGA or a cuffed tube, which is the
// entire reason those are better.
// it is one shot, on its own flag. the first version guarded only on ACM's oral-airway variable being "OPA" and
// cleared it, which should have been self-limiting and was not. guarding on somebody else's state to decide
// whether your own code has already run is fragile: anything that rewrites that variable, or any ordering where
// the clear has not propagated yet, and this runs again. it checks a flag it owns now.
params ["_patient"];
if (isNull _patient) exitWith {};

private _oral = _patient getVariable ["ACM_airway_AirwayItem_Oral", ""];

// a fresh OPA in a clean airway rearms it, so the next time they vomit it comes out again.
if (_oral == "OPA" && {(_patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0]) <= 0}) then {
    _patient setVariable ["ACME_opaEjected", false, true];
};

if (_patient getVariable ["ACME_opaEjected", false]) exitWith {};
if (_oral != "OPA") exitWith {};
if ((_patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0]) <= 0) exitWith {};

_patient setVariable ["ACME_opaEjected", true, true];
[_patient, "", true] call ACM_airway_fnc_setOralAirwayItem;

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "Vomited and ejected the OPA", "Emesis, OPA ejected", []] call ACME_fnc_medLog;
};

// told to whoever is actually standing there, rather than broadcast to everyone on the server.
if (hasInterface && {!isNull ACE_player} && {(ACE_player distance _patient) < 8}) then {
    ["The OPA has come out with the vomit. It is gone.", 3] call ace_common_fnc_displayTextStructured;
};

// no body-image event is fired from here. the previous version raised ace_medical_gui_updateBodyImage with empty
// parameters, so ACE's own handler and our et tube handler both received a null unit. that is the "Bad Unit
// <NULL-object>" flood in the RPT, four a second, for as long as this kept re-running.
// the medical menu repaints itself when it is open and picks the change up on its own.
