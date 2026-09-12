// return true if the selected limb currently has a fracture, by checking the ACE and ACM-style fracture state.
// call it as [_patient, _bodyPart] call ACME_fnc_directPressureHasFracture.
params ["_patient", ["_bodyPart", ""]];
_bodyPart = toLower _bodyPart;
if (isNull _patient) exitWith {false};
if !(_bodyPart in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {false};

private _idx = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find _bodyPart;
if (_idx < 0) exitWith {false};

private _has = false;

// ACE medical stores fractures as a body-part array on most builds.
private _fractures = _patient getVariable ["ace_medical_fractures", []];
if (_fractures isEqualType [] && {count _fractures > _idx}) then {
    private _v = _fractures select _idx;
    if (_v isEqualType true && {_v}) then {_has = true};
    // ACE writes -1 for a splinted fracture and a positive value for an open one. the bone is still broken
    // either way, so anything other than zero counts. the old test only accepted a positive value, which is why
    // pressing on a splinted limb did nothing at all.
    if (_v isEqualType 0 && {_v != 0}) then {_has = true};
    if (_v isEqualType "" && {_v != "" && {toLower _v != "none"}}) then {_has = true};
};
if (_has) exitWith {true};

// defensive fallbacks for the ACM and mission-side fracture vars, if present.
{
    private _v = _patient getVariable [_x, false];
    if (_v isEqualType true && {_v}) exitWith {_has = true};
    if (_v isEqualType 0 && {_v != 0}) exitWith {_has = true};
    if (_v isEqualType "" && {_v != "" && {toLower _v != "none"}}) exitWith {_has = true};
} forEach [
    format ["ace_medical_fracture_%1", _bodyPart],
    format ["ACM_fracture_%1", _bodyPart],
    format ["ACME_fracture_%1", _bodyPart]
];
if (_has) exitWith {true};

private _named = _patient getVariable ["ACM_fractures", []];
if (_named isEqualType []) then {
    {
        if ((toLower str _x) == _bodyPart) exitWith {_has = true};
    } forEach _named;
};
if (_has) exitWith {true};

false
