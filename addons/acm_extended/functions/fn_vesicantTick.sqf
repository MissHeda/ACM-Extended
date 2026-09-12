// ramp the local vesicant pain while peripheral or ej exposure continues, and recover the injury once the infusion
// stops. there is no treatment for extravasation itself, and time, plus elevation and a wrapped bruise, is all
// you have. it does not apply limb damage, bleeding, ACE trauma or necrosis.
// the system toggle is read live, so unticking extravasation in addon options stops this system immediately and
// completely with no mission restart.
if !(missionNamespace getVariable ["ACME_sys_vesicant", true]) exitWith {};
if (isNil "ACME_vesicant_patients") exitWith {};
if (ACME_vesicant_patients isEqualTo []) exitWith {};

private _now = CBA_missionTime;
private _activeWindow = missionNamespace getVariable ["ACME_vesicant_activeWindowSec", 20];
private _ramp = missionNamespace getVariable ["ACME_vesicant_painRampPerSec", 0.0035];
private _maxPain = missionNamespace getVariable ["ACME_vesicant_painMax", 0.45];
private _extSec = missionNamespace getVariable ["ACME_vesicant_extensiveExposureSec", 300];
private _tickSec = 2;  // this pfh runs every 2 s.

// the recovery tunables.
private _recStartSec = missionNamespace getVariable ["ACME_vesicant_recoverStartSec", 30];
private _recPerMin   = missionNamespace getVariable ["ACME_vesicant_recoverPerMin", 0.5];
private _mildStage   = missionNamespace getVariable ["ACME_vesicant_mildResolveStage", 1];
private _floorStage  = missionNamespace getVariable ["ACME_vesicant_severeFloorStage", 2];
private _elevMult    = missionNamespace getVariable ["ACME_vesicant_elevateRecoverMult", 1.6];
private _wrapMult    = missionNamespace getVariable ["ACME_vesicant_wrapRecoverMult", 1.4];

ACME_vesicant_patients = ACME_vesicant_patients select {!isNull _x};

{
    private _patient = _x;
    if (local _patient && {missionNamespace getVariable ["ACME_vesicant_enabled", true]}) then {
        private _records = _patient getVariable ["ACME_vesicant_records", []];
        private _elevated = [_patient] call ACME_fnc_headElevEffective;
        private _painEnabled = missionNamespace getVariable ["ACME_vesicant_painEnabled", true];
        private _target = 0;
        {
            _x params ["_key", "_bp", "_classname"];
            private _cur = _patient getVariable [_key, []];
            if !(_cur isEqualTo []) then {
                private _startT   = _cur param [1, -1];
                private _stage    = _cur param [2, -1];
                private _lastDoseT= _cur param [3, -1];
                private _painScale= _cur param [5, 1];
                private _bruiseFromStage = _cur param [9, 0];

                private _active = _lastDoseT >= 0 && {(_now - _lastDoseT) <= _activeWindow};

                // the pain while exposure is active.
                if (_active && {_painEnabled}) then {
                    private _stagePain = switch (_stage) do {
                        case 0: { missionNamespace getVariable ["ACME_vesicant_painMild", 0.08] };
                        case 1: { missionNamespace getVariable ["ACME_vesicant_painModerate", 0.18] };
                        case 2: { ((missionNamespace getVariable ["ACME_vesicant_painModerate", 0.18]) + (missionNamespace getVariable ["ACME_vesicant_painExtensive", 0.35])) * 0.5 };
                        case 3: { missionNamespace getVariable ["ACME_vesicant_painExtensive", 0.35] };
                        default { 0 };
                    };
                    private _timePain = if (_startT >= 0) then { linearConversion [0, _extSec, _now - _startT, 0, missionNamespace getVariable ["ACME_vesicant_painExtensive", 0.35], true] } else { 0 };
                    _target = _target max (((_stagePain max _timePain) * _painScale) min _maxPain);
                };

                // recovery once the infusion has stopped, or an antidote is actively reversing.
                private _lastAntidoteT = _cur param [11, -1];
                private _antidoteActive = _lastAntidoteT >= 0 && {(_now - _lastAntidoteT) <= (missionNamespace getVariable ["ACME_vesicant_antidoteWindowSec", 90])};
                // the correct antidote lets recovery start immediately, because it is actively reversing, bypassing the
                // post-infusion delay. otherwise recovery waits out recstartsec after the last dose.
                private _recovering = (!_active) && {_stage >= 0} && {_antidoteActive || {_lastDoseT >= 0 && {(_now - _lastDoseT) >= _recStartSec}}};
                if (_recovering) then {
                    // the permanent floor. mild exposures, never above _mildStage, fully resolve to -1, meaning gone. exposures that
                    // reached _floorStage or higher leave a lasting floor at stage-1, and they never fully clear without evac to
                    // definitive care.
                    private _maxStageReached = _stage;  // _stage here is the stored high-water mark.
                    private _floor = if (_maxStageReached >= _floorStage) then { (_maxStageReached - 1) max _mildStage } else { -1 };
                    // the correct antidote reverses lasting injury that time alone would not: while it is active the floor drops, so a
                    // treated severe extravasation can recover further, even fully, unlike an untreated one which is left with the
                    // permanent floor.
                    if (_antidoteActive && {(_cur param [12, 1]) >= 0.5}) then {
                        _floor = if (_maxStageReached >= (_floorStage + 1)) then { _mildStage } else { -1 };
                    };

                    // track a continuous recovery position. it starts at the reached stage and heals down toward the floor.
                    private _pos = _cur param [10, _maxStageReached];
                    private _rate = _recPerMin;
                    // the matching antidote is the biggest accelerator, and elevation and a wrapped bruise stack on top.
                    if (_antidoteActive) then { _rate = _rate * (1 + (((missionNamespace getVariable ["ACME_vesicant_antidoteRecoverMult", 3.0]) - 1) * (_cur param [12, 1]))); };
                    if (_elevated) then { _rate = _rate * _elevMult; };
                    // a wrapped bruise on this part accelerates it too.
                    private _bandaged = _patient getVariable ["ace_medical_bandagedWounds", createHashMap];
                    private _bWounds = _bandaged getOrDefault [_bp, []];
                    if ((_bWounds findIf { (_x param [0, -1]) in [20, 21, 22] }) >= 0) then { _rate = _rate * _wrapMult; };

                    _pos = (_pos - (_rate * (_tickSec / 60))) max _floor;

                    // the visible stage follows the recovery position, rounded, so the bruises step down as it heals.
                    private _newStage = if (_pos < 0) then { -1 } else { floor (_pos + 0.5) };

                    // clear or step the bruise wound as the stage drops.
                    if (_newStage < _stage) then {
                        private _wounds = _patient getVariable ["ace_medical_openWounds", createHashMap];
                        private _woundsOnPart = _wounds getOrDefault [_bp, []];
                        // remove one bruise of the id of the old stage, if the old stage was a bruising stage.
                        if (_stage >= _bruiseFromStage) then {
                            private _oldBruiseID = [20, 21, 22, 22] select (_stage min 3);
                            private _idx = _woundsOnPart findIf { (_x param [0, -1]) == _oldBruiseID && {(_x param [2, 1]) <= 0} };
                            if (_idx >= 0) then {
                                private _w = _woundsOnPart select _idx;
                                private _amt = (_w param [1, 1]) - 1;
                                if (_amt <= 0) then { _woundsOnPart deleteAt _idx; } else { _w set [1, _amt]; };
                                _wounds set [_bp, _woundsOnPart];
                                [_patient, [["openWounds", _wounds, true, true]]] call ACM_core_fnc_setAceMedicalState;
                            };
                        };
                    };

                    if (_newStage < 0) then {
                        // fully resolved: drop the state of the record entirely.
                        [_patient, _key, nil] call ACME_fnc_setVarNet;
                    } else {
                        _cur set [2, _newStage];
                        _cur set [10, _pos];
                        [_patient, _key, _cur] call ACME_fnc_setVarNet;
                    };
                };
            };
        } forEach _records;

        // apply or fade the pain.
        if (_target > 0) then {
            if (_painEnabled) then {
                private _oldApplied = _patient getVariable ["ACME_vesicant_painApplied", 0];
                private _newApplied = (_oldApplied + (_ramp * 2)) min _target;
                if (_newApplied > (_oldApplied + 0.001)) then {
                    [_patient, "ACME_vesicant_painApplied", _newApplied] call ACME_fnc_setVarNet;
                    private _curPain = _patient getVariable ["ace_medical_pain", 0];
                    if (_curPain < _newApplied) then {
                        [_patient, [["pain", _newApplied, true, true]]] call ACM_core_fnc_setAceMedicalState;
                    };
                };
            };
        } else {
            // no active exposure: fade the applied pain floor so it does not linger forever.
            private _oldApplied = _patient getVariable ["ACME_vesicant_painApplied", 0];
            if (_oldApplied > 0) then {
                private _fade = (missionNamespace getVariable ["ACME_vesicant_recoverPainFade", 0.06]) * (_tickSec / 60);
                [_patient, "ACME_vesicant_painApplied", ((_oldApplied - _fade) max 0)] call ACME_fnc_setVarNet;
            };
        };
    };
} forEach ACME_vesicant_patients;
