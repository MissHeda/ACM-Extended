// pressor-driven MAP support for the CPP, gated on volume.
// if the patient is under-resuscitated, a pressor does little or nothing, and can be penalized, so the lesson is
// blood first. this returns the effective MAP contribution the caller should apply, plus whether it was gated.
// _requestedDelta is the MAP rise the pressor would give if the volume were adequate.
params ["_patient", ["_requestedDelta", 0]];
if (isNull _patient) exitWith {[0, true]};

private _adequate = [_patient] call ACME_fnc_tbiIsVolumeAdequate;
if (!_adequate) exitWith {
    // hypovolemic: the pressor is squeezing an empty tank. there is no real CPP benefit, and an optional penalty models
    // the worsened perfusion and lactate. it is off by default, so set it above 0.
    private _penalty = missionNamespace getVariable ["ACME_tbi_pressorOnEmptyPenalty", 0];  // todo[ref]
    if (_penalty > 0) then {
        private _state = _patient getVariable ["ACME_tbi_State", createHashMap];
        if (count _state > 0) then {
            _state set ["severity", ((_state getOrDefault ["severity", 0.5]) + _penalty) min 1];
            [_patient, _state] call ACME_fnc_tbiStateCommit;
        };
    };
    [0, true]
};

// the volume is adequate, so the pressor does real work, capped so it cannot substitute for the rest of the
// resuscitation.
private _cap = missionNamespace getVariable ["ACME_tbi_pressorMAPcap", 25];  // todo[ref]
[(_requestedDelta min _cap), false]
