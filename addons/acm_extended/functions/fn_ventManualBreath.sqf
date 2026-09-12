// a manual breath. it delivers one mandatory breath, right now, on the command of the operator.
// this is the button you reach for when the machine is not breathing for the patient and you need it to:
// on CPAP with a casualty who has no respiratory drive, because the mode cannot ventilate them, see
// fn_ventdrivetick, so a manual breath is the only way to move gas without changing mode.
// to stack an extra breath on a hypoventilating patient.
// and to test the circuit and confirm the chest rises after intubation.
// the breath is delivered at the current settings and through the current lung, so it is not a free win. a stiff
// lung, from blast lung or edema, gets a smaller VTe out of a pressure-limited breath exactly as it would from
// the machine, and the pressure it takes to push a volume in is the same pressure that can injure it.
// call it as [] call ACME_fnc_ventManualBreath.
private _patient = uiNamespace getVariable ["ACME_vent_target", objNull];
if (isNull _patient) exitWith {
    ["No patient connected.", 1.5] call ace_common_fnc_displayTextStructured;
};

// Capture patient and device identity before leaving the panel owner.
if (missionNamespace getVariable ["ACME_vent_simpleMode", false]) exitWith {
    private _serial = (uiNamespace getVariable ["ACME_vent_manualRequestSerial", 0]) + 1;
    uiNamespace setVariable ["ACME_vent_manualRequestSerial", _serial];
    private _id = format ["ventManual:%1:%2:%3", clientOwner, diag_tickTime, _serial];
    private _episode = (_patient getVariable ["ACME_vent_simpleEpisode", [false, 0]]) select 1;
    ["ACME_ventSimpleManualBreath", [_patient, ACE_player, _patient getVariable ["ACME_vent_custodyId", ""],
        [_patient] call ACME_fnc_clinicalEpoch, CBA_missionTime, _id, _episode], _patient] call CBA_fnc_targetEvent;
};

private _configured = _patient getVariable ["ACME_vent_configured", false];
private _connected  = _patient getVariable ["ACME_vent_connected", false];
private _iface      = _patient getVariable ["ACME_vent_iface", ""];
private _ettIn      = _patient getVariable ["ACME_ETT_Inserted", false];
private _igelIn  = ((_patient getVariable ["ACM_airway_AirwayItem_Oral", ""]) isEqualTo "SGA");
private _cricIn  = (_patient getVariable ["ACM_airway_SurgicalAirway_TubeInserted", false]);
// any secured airway, not just an ETT. fn_ventdrivetick has always resolved all three, the ETT, the cric and the
// i-gel, and the machine drives happily through any of them, and this file only ever asked about the tube, so a
// casualty on an i-gel or a cric read as having nothing in their airway at all.
private _securedAirway = _ettIn || _igelIn || _cricIn;


if (!_configured || {!_connected}) exitWith {
    ["Not connected to a patient.", 1.5] call ace_common_fnc_displayTextStructured;
};
// a breath has to have somewhere to go. the drive engine only ventilates through INVASIVE, the et tube, see
// fn_ventdrivetick, so the manual breath obeys the same rule rather than inventing a second one. you cannot
// hand-breathe someone through a nebulizer, and this sim does not model a sealed niv mask well enough to pretend
// otherwise.
if (_iface != "INVASIVE") exitWith {
    ["Manual breath requires an INVASIVE interface.", 2] call ace_common_fnc_displayTextStructured;
};
if (!_securedAirway) exitWith {
    ["No secured airway on this casualty.", 1.5] call ace_common_fnc_displayTextStructured;
};

// a refractory period. you cannot physically bag someone faster than this, and without it the button could be
// mashed to fabricate an absurd minute ventilation.
private _now = CBA_missionTime;
private _minGap = missionNamespace getVariable ["ACME_vent_manualBreathMinGap", 1.5];
private _lastT = _patient getVariable ["ACME_vent_manualBreathT", -999];
if ((_now - _lastT) < _minGap) exitWith {};

// deliver the breath through the current lung and the current settings.
private _mode  = _patient getVariable ["ACME_vent_mode", "SIMV VC PS"];
private _vtSet = (_patient getVariable ["ACME_vent_vt", 500]) max 1;
private _fio2  = _patient getVariable ["ACME_vent_fio2", 21];
private _comp  = _patient getVariable ["ACME_vent_compliance", 1];
if (_comp <= 0) then { _comp = 1 };

// a manual breath is a mandatory breath, so it is volume-targeted and a stiff lung costs pressure rather than
// volume. in pressure control the machine caps the pressure and loses volume, and the operator squeezing the
// button is asking for a breath, so they get one, at whatever pressure that lung demands.
private _vti = _vtSet;
private _pip = 8 + (12 * (_vtSet / 500) / _comp);

// leak: the same as the drive engine. an open chest or a draining tube loses part of every breath, manual or
// not.
private _ptx = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _leak = 0.03;
if (_ptx > 0) then { _leak = _leak + (0.10 * (linearConversion [0, 3, _ptx, 0, 1, true])); };
if ((_patient getVariable ["ACME_thora_tube_left", false]) || {_patient getVariable ["ACME_thora_tube_right", false]}) then {
    _leak = _leak + 0.08;
};
_leak = _leak min 0.45;
private _vte = _vti * (1 - _leak);

_patient setVariable ["ACME_vent_vti", round _vti, true];
_patient setVariable ["ACME_vent_vte", round _vte, true];
_patient setVariable ["ACME_vent_pip", round _pip, true];

// drive ACM's gas exchange.
// register the breath the same way the drive engine does, so the oxygenation branch actually runs.
private _o2 = _fio2 > 21;
private _bvmState = [["bvmProvider", _patient], ["bvmLastBreath", _now], ["bvmConnectedOxygen", _o2]];
if (_o2) then {_bvmState pushBack ["bvmLastBreathOxygen", _now];};
[_patient, _bvmState, true] call ACM_breathing_fnc_setRuntimeState;

// record the breath.
// a rolling 60 s window of manual breaths is the respiratory rate of the patient while you are hand-breathing
// them. the override, in overrides/fn_updateRespirationRate.sqf, reads this, which is what stops ACM's apnea
// branch from forcing rr to 0 and silently discarding every manual breath on a paralyzed casualty. without it,
// this button would appear to work and do absolutely nothing, which is exactly the trap the BVM-forced rate fell
// into.
private _times = _patient getVariable ["ACME_vent_manualBreathTimes", []];
_times pushBack _now;
_times = _times select {(_now - _x) <= 60};
_patient setVariable ["ACME_vent_manualBreathTimes", _times, true];
_patient setVariable ["ACME_vent_manualRR", (count _times), true];
_patient setVariable ["ACME_vent_manualBreathT", _now, true];

// barotrauma applies to a manual breath too: forcing a volume into a stiff lung is the same insult whether the
// machine did it or you did.
private _pipDanger = missionNamespace getVariable ["ACME_vent_baroPIPThreshold", 35];
if (_pip > _pipDanger) then {
    private _dose = _patient getVariable ["ACME_vent_baroDose", 0];
    _patient setVariable ["ACME_vent_baroDose", (_dose + 0.02), true];
};

// kick the gauge, so the operator sees the breath go in.
uiNamespace setVariable ["ACME_vent_manualGaugeT", diag_tickTime];
