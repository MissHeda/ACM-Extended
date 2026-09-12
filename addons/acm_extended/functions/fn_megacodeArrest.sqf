/* Training uses the same native transition/ROSC contract as live patients. */
params ["_p", "_code", ["_arrest", true]];
if (isNull _p || {!local _p}) exitWith {};
if (_arrest) then {
    if (_code == 102) then {[_p, 102] call ACME_fnc_rhythmSet;} else {[_p, if (_code == 4) then {3} else {_code}] call ACME_fnc_arrestLocal;};
} else {[_p, [_p] call ACME_fnc_clinicalEpoch] call ACME_fnc_shockROSC;};
