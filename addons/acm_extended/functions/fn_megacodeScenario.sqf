// the megacode scenario trigger. it starts a timed, multi-stage clinical deterioration on the manikin: each stage
// pushes new vitals, rhythm or pathology, and most scenarios end in a cardiac arrest the trainee must work.
// it is more capable than the patient spawner of ACM, because it does not simply place a static casualty, it drives
// an evolving situation. the button calls this on the instructor, and the progression runs on the owner of the
// manikin, the server, stepped by ACME_fnc_megacodeScenarioTick. "stop" cancels a running scenario.
// _this is [_key], from a scenario button, or [_key, _d, _op] for the owner re-invoke.
params ["_key", ["_d", objNull], ["_op", objNull]];
private _owner = !(isNull _d);
if (isNull _d) then { _d = uiNamespace getVariable ["ACME_MC_target", objNull]; _op = ACE_player; };
if (isNull _d) exitWith {};
private _k = toLower _key;

private _names = createHashMapFromArray [
    ["stop",           "Scenario stopped"],
    ["acs_vf",         "ACS -> VF arrest"],
    ["tension_pea",    "Tension pneumo -> PEA"],
    ["hemorrhage_pea", "Hemorrhagic shock -> PEA"],
    ["hyperk_vf",      "Hyperkalemia -> VF"],
    ["icp_herniation", "Rising ICP -> herniation -> arrest"],
    ["hypoxia_asys",   "Hypoxia -> bradyasystole"],
    ["sepsis_pea",     "Septic shock -> PEA"]
];
private _name = _names getOrDefault [_k, _key];

// the instructor-side feedback, only on the first, button-driven call.
if (!_owner) then {
    if (_k isEqualTo "stop") then {
        ["Megacode scenario stopped.", 2.5] call ace_common_fnc_displayTextStructured;
        [["Scenario stopped", "#ffb24d"]] call ACME_fnc_megacodeLog;
    } else {
        [format ["Scenario started: %1", _name], 3] call ace_common_fnc_displayTextStructured;
        [[format ["SCENARIO: %1", _name], "#c39bff"]] call ACME_fnc_megacodeLog;
    };
    [87300, "scenario"] call ACME_fnc_megacodeMenu;
};

// run the sim where the manikin is local, and hand off if we are not there.
if (!local _d) exitWith {
    if (!_owner) then { [_key, _d, _op] remoteExec ["ACME_fnc_megacodeScenario", _d]; };
};

// the owner: stop any running scenario first.
private _oldPFH = _d getVariable ["ACME_MC_scenPFH", -1];
if (_oldPFH >= 0) then { [_oldPFH] call CBA_fnc_removePerFrameHandler; };
_d setVariable ["ACME_MC_scenPFH", -1, false];
_d setVariable ["ACME_MC_scenActive", false, true];
_d setVariable ["ACME_MC_scenName", "", true];
if (_k isEqualTo "stop") exitWith {};

// a stage is [atsec, label, hr, spo2, sbp, dbp, rr, etco2, rhythmkey, extra], where -1 keeps a vital and "" means
// none.
private _stages = switch (_k) do {
    case "acs_vf": { [
        [0,   "Chest pain, ST elevation",   104, 95, 150, 92, 22, 38, "stach", ""],
        [45,  "Ischemic, hypotensive",      120, 90,  96, 60, 24, 34, "stach", ""],
        [90,  "Runs of VT",                 180, 86,  80, 50, 26, 30, "vt",    ""],
        [120, "VF arrest",                   -1, -1,  -1, -1, -1, -1, "vfib",  ""]
    ] };
    case "tension_pea": { [
        [0,  "Penetrating chest, dyspneic", 112, 92, 124, 78, 28, 34, "stach", "pneumo"],
        [40, "Tension physiology",          132, 82,  92, 58, 34, 26, "stach", "tpneumo"],
        [85, "Obstructive PEA arrest",       -1, 68,  -1, -1, -1, 12, "pea",   ""]
    ] };
    case "hemorrhage_pea": { [
        [0,  "Junctional hemorrhage, Class II", 120, 96, 104, 66, 22, 36, "stach", "junc_legs"],
        [40, "Class IV hemorrhagic shock",     142, 88,  72, 42, 30, 26, "stach", ""],
        [90, "PEA arrest",                       -1, 70,  -1, -1, -1, 14, "pea",   ""]
    ] };
    case "hyperk_vf": { [
        [0,  "Peaked T waves, weakness",     88, 96, 132, 84, 18, 38, "sinus",  ""],
        [40, "Widening QRS, bradycardia",    44, 92, 110, 70, 16, 34, "sbrady", ""],
        [80, "Sine wave -> VF",              -1, -1,  -1, -1, -1, -1, "vfib",   ""]
    ] };
    case "icp_herniation": { [
        [0,   "Rising ICP, severe headache", 76, 97, 150, 92, 16, 38, "sinus", "icp_rise"],
        [45,  "Cushing's triad",             48, 95, 200, 110, 8, 30, "sbrady", "cushing"],
        [95,  "Herniation, coma",            42, 90, 205, 112, 6, 26, "sbrady", "herniation"],
        [135, "Bradyasystolic arrest",       -1, -1,  -1, -1, -1, -1, "asystole", ""]
    ] };
    case "hypoxia_asys": { [
        [0,  "Airway compromise, hypoxia",  112, 84, 120, 76, 8, 30, "stach",  "hypoxia"],
        [40, "Severe hypoxia, bradycardia",  40, 62,  92, 56, 6, 22, "sbrady", ""],
        [80, "Asystole",                     -1, -1,  -1, -1, -1, -1, "asystole", ""]
    ] };
    case "sepsis_pea": { [
        [0,   "Warm septic shock",          122, 94,  94, 44, 26, 30, "stach", "fever"],
        [50,  "Refractory hypotension",     140, 86,  70, 38, 30, 24, "stach", ""],
        [100, "PEA arrest",                  -1, 78,  -1, -1, -1, 16, "pea",   ""]
    ] };
    default { [] };
};
if (_stages isEqualTo []) exitWith {};

private _pace = (missionNamespace getVariable ["ACME_megacode_scenarioPace", 1.0]) max 0.1;
{ _x set [0, (_x select 0) * _pace] } forEach _stages;

_d setVariable ["ACME_MC_scenStages", _stages, false];
_d setVariable ["ACME_MC_scenIdx", 0, false];
_d setVariable ["ACME_MC_scenStart", CBA_missionTime, false];
_d setVariable ["ACME_MC_scenOp", _op, false];
_d setVariable ["ACME_MC_scenName", _name, true];
_d setVariable ["ACME_MC_scenActive", true, true];

private _pfh = [{ _this call ACME_fnc_megacodeScenarioTick }, 1.0, [_d]] call CBA_fnc_addPerFrameHandler;
_d setVariable ["ACME_MC_scenPFH", _pfh, false];
