// passive heimlich-valve drainage: while a chest tube is in, slowly drain the pleural blood, Hemothorax_Fluid, at a
// capped rate, and periodically leave blood on the ground. the manual ACCUVAC and suction still drains everything
// at once.
// it starts one pfh per patient, idempotently. the arg is [_patient].
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
    private _tubeIn = (_patient getVariable ["ACME_thora_tube_left", false]) || {_patient getVariable ["ACME_thora_tube_right", false]};
    if (!alive _patient || {!_tubeIn}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        _patient setVariable ["ACME_thora_drainPFH", -1];
    };
    private _fluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];
    // fresh blood that arrived since the last pass. with the tube draining, a rise means the casualty is still
    // bleeding into the chest, and that is what the hourly figure reports.
    private _seen = _patient getVariable ["ACME_thora_fluidSeen", _fluid];
    private _newBleed = (_fluid - _seen) max 0;
    if (_fluid > 0) then {
        // bilateral tubes outpace the chest.
        // one tube empties a chest slowly enough that a casualty who keeps bleeding into it still accumulates,
        // and the hemothorax physiology continues to bite. two tubes drain faster than the pleural space can
        // refill, so the blood leaves as quickly as it arrives and the casualty stops being a hemothorax
        // problem. that is the purpose of putting the second one in.
        // it does not stop the bleeding. the blood is still leaving the circulation, it is leaving through the
        // tube instead of collecting in the chest, and the running output figure shows exactly how much.
        private _bilateral = (_patient getVariable ["ACME_thora_tube_left", false])
            && {_patient getVariable ["ACME_thora_tube_right", false]};
        private _rate = if (_bilateral) then {
            missionNamespace getVariable ["ACME_thora_bilateralDrainPerMin", 3]
        } else {
            missionNamespace getVariable ["ACME_thora_passiveDrainPerMin", 0.12]
        };
        private _perSec = _rate / 60;
        private _newFluid = (_fluid - (_perSec * _dt)) max 0;
        [_patient, [["hemothoraxFluid", _newFluid]], true] call ACM_breathing_fnc_setRuntimeState;
        // what actually left the chest this second is tallied. the output figure and the two surgical thresholds
        // are the reason the tube exists as a decision tool rather than only a drain.
        [_patient, (_fluid - _newFluid), _newBleed] call ACME_fnc_thoraOutput;
        [_patient, "fluidSeen", _newFluid, false] call ACME_fnc_thoraOutputStateCommit;
        if (CBA_missionTime > _nextStain) then {
            [_patient] call ACME_fnc_thoraBloodStain;
            _args set [1, CBA_missionTime + (missionNamespace getVariable ["ACME_thora_bloodStainInterval", 6])];
        };
    };
}, 1, [_patient, 0, CBA_missionTime]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_thora_drainPFH", _pfh];
// the rate window is measured from the moment the tube starts draining, not from mission start.
if ((_patient getVariable ["ACME_thora_outputStart", -1]) < 0) then {
    [_patient, "start", CBA_missionTime, true] call ACME_fnc_thoraOutputStateCommit;
};
