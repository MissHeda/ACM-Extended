// apply an XStat 30 hemostatic sponge bolus to an inguinal, meaning leg, junctional wound. it is an extreme-case
// device: far faster than gauze packing, at a 3 s insert against a 15 s pack plus a 15 s wrap, and the bleed ramps
// to fully controlled over about _xRamp s, defaulting to 12.
// the wound never resolves on its own. it is held by the bolus and is permanent until surgery or a full heal.
// the junctional state becomes "xstat": the wound icon stays and the injury row goes green with "[XStat]".
// the casualty is silently flagged as needing surgical care to remove it.
// the leg is permanently impaired, on forcewalk with no sprint, until a full heal.
// a 2-hour dwell limit is watched by the bleed pfh: if there is no surgery by then, it rebleeds.
// it cannot be removed, replaced, reapplied or stacked, because the apply action only offers it on a fresh open
// inguinal wound with no AAJT in place, and no XStat remove action exists.
// _this is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
private _p = toLower _bodyPart;
if !(_p in ["leftleg", "rightleg"]) exitWith {
    ["XStat may only be used on an inguinal (leg) junctional wound.", 2.5] call ace_common_fnc_displayTextStructured;
};

// seat the bolus. record the seat time, which drives the ramp and the dwell timer, and clear any stale pack
// flags.
_patient setVariable [format ["ACME_Junc_%1", _p], "xstat", true];
_patient setVariable [format ["ACME_Junc_XStatAt_%1", _p], time, true];
_patient setVariable [format ["ACME_Junc_XStatRebled_%1", _p], false, true];
_patient setVariable [format ["ACME_Junc_Packing_%1", _p], false, true];
_patient setVariable [format ["ACME_Junc_PackedAt_%1", _p], -1, true];

// the silent surgical flag. only a hospital or a full heal can take the XStat out.
_patient setVariable ["ACME_XStat_needsSurgery", true, true];

// a permanent leg handicap: no sprint while the bolus is in. forcewalk is patient-local.
_patient setVariable ["ACME_XStat_impaired", true, true];
if (local _patient) then { _patient forceWalk true } else { [_patient, true] remoteExec ["ACME_fnc_forceWalkLocal", _patient] };

// the wound was an open bleeder, so the pfh is already running. this simply guarantees it, and the ramp.
[_patient] call ACME_fnc_junctionalStartBleed;

["XStat inserted.", 3.5] call ace_common_fnc_displayTextStructured;
