// Shared Direct Pressure per-frame worker. Direct Pressure itself never owns ACM's global continuous-action gate.
// Movement yields pressure on another casualty, while ordinary medical treatments may replace only the provider
// animation. True ACM maneuvers suspend both the pose and the clinical pressure marker, then the hold resumes after
// the maneuver finishes. This keeps every medical-menu action responsive without granting hemorrhage control while
// the provider is physically performing an incompatible maneuver.
params ["_args", "_pfhId"];
_args params ["_medic", "_patient", "_bodyPart", "_mode"];

if !(_medic getVariable ["ACME_DP_Active", false]) exitWith {[_pfhId] call CBA_fnc_removePerFrameHandler;};
if !(missionNamespace getVariable ["ACME_sys_dp", true]) exitWith {
    [false, _medic, false] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

private _stop = "";
if (!alive _medic || {_medic getVariable ["ACE_isUnconscious", false]}) then {_stop = "down";};
if (_stop == "" && {isNull _patient}) then {_stop = "patient";};

private _leash = if (_mode == "torso") then {2.2} else {missionNamespace getVariable ["ACME_DP_leashDist", 1.7]};
private _medicVehicle = objectParent _medic;
private _patientVehicle = objectParent _patient;
if (_stop == "" && {_medicVehicle isNotEqualTo _patientVehicle}) then {_stop = "far";};
if (_stop == "" && {(_medic distance _patient) > _leash}) then {_stop = "far";};

if (_stop != "") exitWith {
    if (_stop == "far") then {["Direct pressure released.", 2, _medic] call ace_common_fnc_displayTextStructured;};
    [true, _medic, false] call ACME_fnc_directPressureStop;
    [_pfhId] call CBA_fnc_removePerFrameHandler;
};

// Torso, head and limb pressure share the same yield/resume pose controller. It retires the looping hold on movement
// or when another treatment owns the provider animation and reapplies it after the provider settles again.
if (_mode in ["torso", "limb"]) then {[_medic, _patient] call ACME_fnc_directPressurePose;};

private _moveInput = (inputAction "MoveForward") + (inputAction "MoveBack")
                   + (inputAction "MoveLeft") + (inputAction "MoveRight")
                   + (inputAction "MoveFastForward") + (inputAction "MoveSlowForward")
                   + (inputAction "Evasive");
private _moving = (_mode != "self") && {_moveInput > 0.01};
private _maneuverActive = missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false];
private _manualPause = _medic getVariable ["ACME_DP_Paused", false];
private _mustYieldClinical = _moving || {_maneuverActive} || {_manualPause};
private _yieldedClinical = _medic getVariable ["ACME_DP_ClinicalYield", false];

if (_mustYieldClinical) exitWith {
    if (!_yieldedClinical) then {
        if ((_patient getVariable [format ["ACME_DP_press_%1", _bodyPart], objNull]) isEqualTo _medic) then {
            _patient setVariable [format ["ACME_DP_press_%1", _bodyPart], objNull, true];
        };
        _medic setVariable ["ACME_DP_ClinicalYield", true];
        _medic setVariable ["ACME_DP_ClinicalYieldStart", CBA_missionTime];
    };
};

// Reapply the synchronized pressure marker once the incompatible activity ends. Shift both clot timers by the exact
// yielded duration so time spent walking, assessing, or performing another maneuver never counts as pressure time.
if (_yieldedClinical) then {
    private _yieldStart = _medic getVariable ["ACME_DP_ClinicalYieldStart", CBA_missionTime];
    private _yieldDuration = (CBA_missionTime - _yieldStart) max 0;
    _medic setVariable ["ACME_DP_Start", (_medic getVariable ["ACME_DP_Start", CBA_missionTime]) + _yieldDuration];
    _medic setVariable ["ACME_DP_NextClot", (_medic getVariable ["ACME_DP_NextClot", CBA_missionTime]) + _yieldDuration];
    _medic setVariable ["ACME_DP_ClinicalYield", false];
    _medic setVariable ["ACME_DP_ClinicalYieldStart", 0];
    _patient setVariable [format ["ACME_DP_press_%1", _bodyPart], _medic, true];
};

private _held = CBA_missionTime - (_medic getVariable ["ACME_DP_Start", CBA_missionTime]);
if (_held < 15) exitWith {};
if (CBA_missionTime < (_medic getVariable ["ACME_DP_NextClot", 0])) exitWith {};
_medic setVariable ["ACME_DP_NextClot", CBA_missionTime + 2];

[_patient, _bodyPart, 2, 3, true, false] call ACM_damage_fnc_clotWoundsOnBodyPart;
