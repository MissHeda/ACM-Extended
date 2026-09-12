// this runs where the target is local. it clears every TBI and ICP variable, matching the teardown the full-heal
// path uses, so a zeus-cleared TBI leaves no residual ICP drive, evac flag or vitals offset.
// call or remoteexec it as [_unit] call ACME_fnc_zeusClearTBILocal.
params ["_unit"];
if (isNull _unit || {!local _unit}) exitWith {};

[_unit, createHashMap] call ACME_fnc_tbiStateCommit;
{
    _unit setVariable [_x, nil, true];
} forEach [
    "ACME_tbi_HasTBI", "ACME_tbi_evacRequired", "ACME_tbi_evacFlagged",
    "ACME_tbi_bpSysOffset", "ACME_tbi_bpDiaOffset", "ACME_tbi_resistAdd", "ACME_tbi_savedRRTarget"
];
