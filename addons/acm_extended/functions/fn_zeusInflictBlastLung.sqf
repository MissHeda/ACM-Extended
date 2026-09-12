// a zeus module entry: inflict blast lung on the unit the module was dropped onto.
// per the Module_F convention, _this is [_logic, _units, _activated], and the attached object is the target.
// the severity is randomized in the moderate-to-severe band, because a mild blast lung is not a training
// scenario.
params ["_logic"];
if (isNull _logic) exitWith {};

private _unit = effectiveCommander (attachedTo _logic);
if (isNull _unit) then { _unit = attachedTo _logic; };

private _cleanup = { if (!isNull _logic) then { deleteVehicle _logic; }; };

if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {
    ["Blast lung module: place it directly on a person.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};
if (!alive _unit) exitWith {
    ["Blast lung module: target must be alive.", 2] call ace_common_fnc_displayTextStructured;
    call _cleanup;
};

private _sev = 0.45 + (random 0.4);  // 0.45 .. 0.85
[_unit, _sev] remoteExec ["ACME_fnc_blastLungInflict", _unit];
[format ["Blast lung inflicted (severity %1).", (_sev * 100) toFixed 0], 2] call ace_common_fnc_displayTextStructured;
call _cleanup;
