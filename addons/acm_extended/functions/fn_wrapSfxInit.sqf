// B32: wrapping sounds follow the real ACE action lifecycle. Treatment callbacks,
// eligibility, items and animation ownership remain with ACM/ACE and the action.
if (missionNamespace getVariable ["ACME_wrapSfxInitialized", false]) exitWith {};
missionNamespace setVariable ["ACME_wrapSfxInitialized", true];

if (isServer) then {
    ["ACME_wrapSfx", {_this call ACME_fnc_wrapSfxServer}] call CBA_fnc_addEventHandler;
};

["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", "_classname"];
    // Junctional callbacks already invoke the shared helper before this event.
    if (toLower _classname == "acme_wrapjunctional") exitWith {};
    private _cfg = configFile >> "ace_medical_treatment_actions" >> _classname;
    private _wrap = toLower _classname == "acme_wraphpmk";
    private _seen = [];
    while {isClass _cfg && {!_wrap}} do {
        private _name = toLower configName _cfg;
        if (_name in _seen) exitWith {};
        _seen pushBack _name;
        _wrap = _name == "elasticwrap";
        _cfg = inheritsFrom _cfg;
    };
    if (_wrap) then {
        _this call ACME_fnc_wrapSfxStart;
    } else {
        // Starting another treatment retires an abandoned wrapping episode.
        [_medic] call ACME_fnc_wrapSfxStop;
    };
}] call CBA_fnc_addEventHandler;

{
    [_x, {_this call ACME_fnc_wrapSfxStop}] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];

