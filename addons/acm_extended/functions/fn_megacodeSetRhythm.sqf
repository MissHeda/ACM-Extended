// apply a cardiac rhythm to the megacode dummy, matched to the real rhythm enum and arrest pathway of ACM.
// perfusing rhythms set the display rhythm and hr target, and rosc the manikin if it was in arrest. arrest rhythms,
// meaning vf, PVT and torsades, asystole and PEA, route through the fatalvitals arrest induction of ACM on the
// owner of the manikin. it refreshes the rhythm page.
// _this is [_key].
params ["_key"];
private _d = uiNamespace getVariable ["ACME_MC_target", objNull];
if (isNull _d) exitWith {};

// the key maps to [displayrhythm, defaulthr, pulseless, acmcode, isarrest].
// the ACM enum is 0 sinus, 1 asystole, 2 vf, 3 PVT and torsades, 4 vt with a pulse and 5 PEA. 100 to 103 are the
// custom rhythms of the mod.
private _map = createHashMapFromArray [
    ["sinus",      ["sinus", 78, false, 0, false]],
    ["stach",      ["sinus", 130, false, 0, false]],
    ["sbrady",     ["sinus", 45, false, 0, false]],
    ["afib",       ["afib", 84, false, 103, false]],
    ["afibrvr",    ["afibrvr", 150, false, 100, false]],
    ["atrialtach", ["atrialtach", 175, false, 101, false]],
    ["svt",        ["svt", 190, false, 104, false]],
    ["vt",         ["vt", 180, false, 4, false]],
    ["torsades",   ["torsades", 0, true, 3, true]],
    ["vfib",       ["vfib", 0, true, 2, true]],
    ["asystole",   ["asystole", 0, true, 1, true]],
    ["pea",        ["sinus", 0, true, 5, true]]
];
private _e = _map getOrDefault [toLower _key, ["sinus", 78, false, 0, false]];
_e params ["_disp", "_hr", "_pulseless", "_code", "_arrest"];

// the monitor display state, which is panel-authoritative.
_d setVariable ["ACME_MC_rhythm", _disp, true];
_d setVariable ["ACME_MC_pulseless", _pulseless, true];
_d setVariable ["ACME_MC_HR", _hr, true];
_d setVariable ["ACME_MC_rhythmKey", toLower _key, true];
[_d, _code, true, false] call ACME_fnc_rhythmActiveCommit;

if (_arrest) then {
    [_d, _code, true] remoteExec ["ACME_fnc_megacodeArrest", _d];
} else {
    // if currently arrested, rosc back to sinus first, then apply the perfusing rhythm.
    if (_d getVariable ["ace_medical_inCardiacArrest", false]) then {
        [_d, 0, false] remoteExec ["ACME_fnc_megacodeArrest", _d];
    };
    [_d, _code] call ACME_fnc_rhythmSet;
    [_d, [["heartRate", _hr]], true] call ACM_core_fnc_setTargetVitalsState;
};

[[format ["Rhythm: %1", toUpper _key], (if (_pulseless) then {"#ff8a8a"} else {"#9be08c"})]] call ACME_fnc_megacodeLog;
[87300, "rhythm"] call ACME_fnc_megacodeMenu;
