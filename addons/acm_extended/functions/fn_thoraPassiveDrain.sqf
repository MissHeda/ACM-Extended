// Passive chest-tube drainage.
//
// Hemothorax_State owns the hemorrhage source. ACM's circulation loop converts that source into pleural blood in
// ACM_breathing_Hemothorax_Fluid. The tube never changes Hemothorax_State and therefore never "treats" the source.
// It only removes fluid that has reached the pleural space.
//
// ACME_thora_passiveDrainPerMin is the MAXIMUM FLOW OF ONE TUBE, in L/min. One tube can therefore keep up with a
// hemothorax only while pleural inflow stays at or below that cap. Any excess remains in Hemothorax_Fluid. A second
// tube contributes one additional identical flow path, so bilateral tubes have exactly 2x the single-tube cap.
// Existing pooled blood also drains against the same total capacity until the chest catches up with ongoing inflow.
params ["_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith { ["ACME_ownerCommand", [_patient, "thoraDrain", []], _patient] call CBA_fnc_targetEvent; };
if ((_patient getVariable ["ACME_thora_drainPFH", -1]) != -1) exitWith {};

private _pfh = [{
    params ["_args", "_h"];
    _args params ["_patient", "_nextStain", "_lastTick"];

    if (isNull _patient || {!local _patient}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        if (!isNull _patient) then { _patient setVariable ["ACME_thora_drainPFH", -1, false]; };
    };

    private _now = CBA_missionTime;
    private _dt = ((_now - _lastTick) max 0) min 5;
    _args set [2, _now];

    private _leftTube = _patient getVariable ["ACME_thora_tube_left", false];
    private _rightTube = _patient getVariable ["ACME_thora_tube_right", false];
    private _tubeCount = (if (_leftTube) then {1} else {0}) + (if (_rightTube) then {1} else {0});

    if (!alive _patient || {_tubeCount <= 0}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        _patient setVariable ["ACME_thora_drainPFH", -1];
    };

    private _fluid = (_patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0]) max 0;
    private _seen = (_patient getVariable ["ACME_thora_fluidSeen", _fluid]) max 0;

    // The observed rise is authoritative whenever the pleural reservoir is below its native 1.5 L ceiling. Once
    // that ceiling is reached, a simple fluid delta can no longer show ongoing hemorrhage, so fall back to ACM's
    // live source-rate function for the output trend rather than incorrectly reporting zero ongoing bleeding.
    private _freshBleed = (_fluid - _seen) max 0;
    if ((_fluid >= 1.499 || {_freshBleed <= 0.000001})
        && {(_patient getVariable ["ACM_breathing_Hemothorax_State", 0]) > 0}
        && {!isNil "ACM_circulation_fnc_getHemothoraxBleedingRate"}) then {
        private _sourcePerSec = ([_patient] call ACM_circulation_fnc_getHemothoraxBleedingRate) max 0;
        _freshBleed = _sourcePerSec * _dt;
    };

    // One cap, multiplied only by the number of tubes. The old implementation used unrelated 0.12 L/min and
    // 3 L/min single/bilateral values, which meant placing the second tube changed capacity by 25x. That path is
    // deliberately gone. Default: 0.12 L/min per tube, 0.24 L/min with two tubes.
    private _perTubePerMin = (missionNamespace getVariable ["ACME_thora_passiveDrainPerMin", 0.12]) max 0;
    private _totalCapacityPerSec = (_perTubePerMin * _tubeCount) / 60;
    private _capacityThisTick = _totalCapacityPerSec * _dt;

    // Drain only blood that is physically present. With no pre-existing pool and source flow below capacity, this
    // naturally equals the hemothorax inflow. Above capacity, only the cap leaves through the tube and the excess
    // remains in Hemothorax_Fluid. A pre-existing pool uses spare capacity until it has been evacuated.
    private _drained = (_fluid min _capacityThisTick) max 0;
    private _newFluid = (_fluid - _drained) max 0;

    if (_drained > 0) then {
        [_patient, [["hemothoraxFluid", _newFluid]], true] call ACM_breathing_fnc_setRuntimeState;
    };

    // Always feed the ongoing source sample to the output history, even on a tick where ordering means the source
    // has not yet deposited enough fluid to drain. Total output still counts only the amount that actually left.
    if (_drained > 0 || {_freshBleed > 0}) then {
        [_patient, _drained, _freshBleed, _now] call ACME_fnc_thoraOutput;
    };
    [_patient, "fluidSeen", _newFluid, false] call ACME_fnc_thoraOutputStateCommit;

    if (_drained > 0 && {_now > _nextStain}) then {
        [_patient] call ACME_fnc_thoraBloodStain;
        private _mlPerSec = (_drained / (_dt max 0.01)) * 1000;
        private _stainDelay = linearConversion [1, 60, _mlPerSec, 12, 2, true];
        _args set [1, _now + _stainDelay];
    };
}, 1, [_patient, 0, CBA_missionTime]] call CBA_fnc_addPerFrameHandler;

_patient setVariable ["ACME_thora_drainPFH", _pfh];

if ((_patient getVariable ["ACME_thora_outputStart", -1]) < 0) then {
    [_patient, "start", CBA_missionTime, true] call ACME_fnc_thoraOutputStateCommit;
};
