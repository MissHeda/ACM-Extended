/* NA3. Native-compatible proxies, with one pulseless torsades contract for all induction paths. */
params ["_unit", ["_code", 0], ["_epoch", -1]];
if (isNull _unit || {!(_code isEqualType 0)}) exitWith {};
if (_epoch < 0) then {_epoch = [_unit] call ACME_fnc_clinicalEpoch;};
if (!local _unit) exitWith {[_unit, "rhythmSet", [_unit, _code, _epoch]] call ACME_fnc_ownerDispatch;};
if (_epoch != ([_unit] call ACME_fnc_clinicalEpoch)) exitWith {};
// B67: invalidate ACM's monitor rhythm cache at the authoritative rhythm write. Native ACM already splices a
// rhythm change into the remainder of the active sweep; this guarantees custom ACME rhythm changes enter that
// path on the very next monitor update instead of waiting for a completed sweep.
private _forceMonitorRefresh = {
    params ["_u"];
    [_u, [["aedPadsLastSync", -1]], true] call ACM_circulation_fnc_setRuntimeState;
    [_u, [["aedEkgRhythm", -99]], true] call ACM_circulation_fnc_setRuntimeState;
};
if (_code == 102) exitWith {
    if (!alive _unit) exitWith {};
    if ((_unit getVariable ["ACME_rhythm_active", 0]) != 102) then {
        [_unit, "ACME_rhythm_torsadesStart", CBA_missionTime] call ACME_fnc_setVarNet;
    };
    [_unit, 102, true, true] call ACME_fnc_rhythmActiveCommit;
    [_unit] call _forceMonitorRefresh;
    [_unit, 3, _epoch] call ACME_fnc_arrestLocal;
    // Native reversible causes may legitimately select a different arrest rhythm.
    if (([_unit] call ACME_fnc_rhythmNative) != 3) then {[_unit] call ACME_fnc_rhythmRelease;};
};
if (_code in [100,101,103,104]) exitWith {
    if (!alive _unit || {_unit getVariable ["ace_medical_inCardiacArrest", false]}) exitWith {};
    // An explicit induction replaces the previous perfusing rhythm. Clear its old ventricular hold here,
    // at the owner-authoritative transition, so the next threshold tick cannot resurrect a stale VT.
    // Observation/ticking never uses this path to clear an actual native deterioration or an arrest.
    [_unit, "", -1, true, true] call ACME_fnc_rhythmNativeHoldCommit;
    [_unit, 0, true, true, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    {
        _x params ["_key", "_value"];
        if (_key isEqualTo "ACM_circulation_CardiacArrest_TargetRhythm") then {
            [_unit, _value] call ACM_circulation_fnc_setCardiacArrestTargetRhythm;
        } else {
            [_unit, _key, _value] call ACME_fnc_setVarNet;
        };
    } forEach [
        ["ACME_rhythmNativeHoldSince", -1],
        ["ACME_rhythmNativeLastSeen", -1],
        ["ACME_rhythmNativeClearStart", -1],
        ["ACME_rhythmThresholdForced", ""],
        ["ACME_rhythmThresholdKind", ""],
        ["ACME_rhythmThresholdStart", -1],
        ["ACM_circulation_CardiacArrest_TargetRhythm", 0]
    ];
    [_unit, "ACME_rhythm_torsadesStart", nil] call ACME_fnc_setVarNet;
    [_unit, _code, true, true] call ACME_fnc_rhythmActiveCommit;
    [_unit, [["cardiacRhythmState", 0]], true] call ACM_circulation_fnc_setRuntimeState;
    [_unit] call _forceMonitorRefresh;
};
if (_code >= -1 && {_code <= 5}) then {
    [_unit, "ACME_rhythm_torsadesStart", nil] call ACME_fnc_setVarNet;
    [_unit] call ACME_fnc_rhythmRelease;
    [_unit, [["cardiacRhythmState", _code]], true] call ACM_circulation_fnc_setRuntimeState;
    [_unit] call _forceMonitorRefresh;
};
