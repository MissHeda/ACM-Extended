// the ventway sparrow status box: the small black square in the header, immediately right of the battery. it shows
// one of three letters, and each one is a real condition rather than a decoration.
// t is a patient trigger detected. the casualty made their own inspiratory effort and the machine saw it. this is
// the single most useful thing on the panel, because it is how you know they still have respiratory drive. a
// paralyzed casualty will never show t, so if you push rocuronium and the t stops, that is the drug working, and
// if t is flickering on a patient you thought was paralyzed, your block is wearing off.
// z is zeroing. the machine is re-zeroing its pressure transducers, which it does at power-on and periodically
// while running. during the zero it is not measuring pressure, so the reading is not to be trusted for those
// couple of seconds.
// c is a cough detected. the patient coughed against the tube. this is the bucking-the-vent signal and it is a
// clinical finding: a casualty who is coughing on an et tube is not adequately sedated. it also spikes the airway
// pressure, so a patient left to fight the tube is being barotraumatised by their own cough.
// the priority when more than one is true is z, because the machine cannot measure at all, then c, because an event
// just happened, then t, which is an ongoing state.
// call it as [_patient] call ACME_fnc_ventStatusTick.
params ["_patient"];
if !(missionNamespace getVariable ["ACME_sys_vent", true]) exitWith {};  // the system toggle. fully off means this stops.
if (isNull _patient || {!alive _patient} || {!(_patient isKindOf "CAManBase")}) exitWith {};

if (!(_patient getVariable ["ACME_vent_configured", false]) || {!(_patient getVariable ["ACME_vent_connected", false])}) exitWith {
    [_patient, "ACME_vent_status", ""] call ACME_fnc_setVarNet;
};

private _now = CBA_missionTime;
private _driving = _patient getVariable ["ACME_vent_driving", false];
private _ettIn = _patient getVariable ["ACME_ETT_Inserted", false];
private _igelIn  = ((_patient getVariable ["ACM_airway_AirwayItem_Oral", ""]) isEqualTo "SGA");
private _cricIn  = (_patient getVariable ["ACM_airway_SurgicalAirway_TubeInserted", false]);
// any secured airway, not just an ETT. fn_ventdrivetick has always resolved all three, the ETT, the cric and the
// i-gel, and the machine drives happily through any of them, and this file only ever asked about the tube, so a
// casualty on an i-gel or a cric read as having nothing in their airway at all.
private _securedAirway = _ettIn || _igelIn || _cricIn;


// z: the periodic auto-zero of the pressure transducers.
private _zeroEvery = missionNamespace getVariable ["ACME_vent_zeroIntervalSecs", 300];  // every 5 min or so.
private _zeroDur   = missionNamespace getVariable ["ACME_vent_zeroDurationSecs", 2.5];
private _nextZero = _patient getVariable ["ACME_vent_nextZeroT", -1];
if (_nextZero < 0) then {
    _nextZero = _now + _zeroEvery;
    [_patient, "ACME_vent_nextZeroT", _nextZero] call ACME_fnc_setVarNet;
};
private _zeroUntil = _patient getVariable ["ACME_vent_zeroUntilT", 0];
if (_now >= _nextZero) then {
    _zeroUntil = _now + _zeroDur;
    [_patient, "ACME_vent_zeroUntilT", _zeroUntil] call ACME_fnc_setVarNet;
    [_patient, "ACME_vent_nextZeroT", _now + _zeroEvery] call ACME_fnc_setVarNet;
};
private _zeroing = _now < _zeroUntil;

// c: a cough.
// a cough needs an intact reflex. that means an et tube to cough against, and a patient who is neither paralyzed
// nor adequately sedated. this is the whole point: the c is telling you your sedation is inadequate.
private _paralyzed = _patient getVariable ["ACME_roc_paralyzed", false];
private _sedLoad = [_patient] call ACME_fnc_sedationOnBoard;
private _sedThresh = (call ACME_fnc_sedationThreshold);
private _sedated = _sedLoad >= _sedThresh;
private _canCough = _securedAirway && {!_paralyzed} && {!_sedated} && {!(_patient getVariable ["ace_medical_inCardiacArrest", false])};

private _coughUntil = _patient getVariable ["ACME_vent_coughUntilT", 0];
if (_canCough && {_driving} && {_now >= (_patient getVariable ["ACME_vent_nextCoughCheckT", 0])}) then {
    [_patient, "ACME_vent_nextCoughCheckT", _now + 5] call ACME_fnc_setVarNet;// roll every 5 s.
    private _chance = missionNamespace getVariable ["ACME_vent_coughChance", 0.22];
    if (random 1 < _chance) then {
        _coughUntil = _now + 1.6;
        [_patient, "ACME_vent_coughUntilT", _coughUntil] call ACME_fnc_setVarNet;
        // a cough is a violent expiratory effort against a closed circuit, so the airway pressure spikes. the patient who
        // is left to fight the tube is injuring their own lung, and the barotrauma engine sees it exactly as it would see
        // the machine over-pressurising them. sedate them and it stops.
        private _pip = _patient getVariable ["ACME_vent_pip", 20];
        private _spike = _pip + (12 + random 14);
        [_patient, "ACME_vent_coughPIP", _spike] call ACME_fnc_setVarNet;
        private _pipDanger = missionNamespace getVariable ["ACME_vent_baroPIPThreshold", 35];
        if (_spike > _pipDanger) then {
            private _dose = _patient getVariable ["ACME_vent_baroDose", 0];
            [_patient, "ACME_vent_baroDose", (_dose + 0.015)] call ACME_fnc_setVarNet;
        };
    };
};
private _coughing = _now < _coughUntil;

// t: a patient trigger.
// the casualty has their own respiratory drive and the machine is seeing their efforts. a paralyzed or apneic
// patient cannot trigger, so this goes dark, which is precisely how you read the block.
private _spontRR = _patient getVariable ["ACME_vent_spontRR", 0];
private _triggering = _driving && {!_paralyzed} && {_spontRR > 0.1} && {!(_patient getVariable ["ACME_roc_apnea", false])};

// resolve.
private _status = switch (true) do {
    case (_zeroing):    { "Z" };
    case (_coughing):   { "C" };
    case (_triggering): { "T" };
    default { "" };
};
[_patient, "ACME_vent_status", _status] call ACME_fnc_setVarNet;
