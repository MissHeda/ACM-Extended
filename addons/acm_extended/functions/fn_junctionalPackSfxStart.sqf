// start the looping junctional packing sfx, and mark the part as being actively packed.
// the ACE callbackstart args are [_medic, _patient, _bodyPart].
// the emitter follows the medic rather than the casualty, so the death or locality of the casualty cannot mute
// it. it is a deletable sound source rather than a say3d, so it ends when the action ends. the packing timer is
// 10 s and the sound file is about 15.9 s, so a one-shot would have run on well past the treatment.
params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic) exitWith {};
private _t = missionNamespace getVariable ["ACME_junctionalPackTime", 10];
if (!isNull _patient) then {
    [_patient, _t] call ACME_fnc_markImportantSfx;
    // the bleed pfh subsides the flow while the hands and gauze tamponade the wound.
    _patient setVariable [format ["ACME_Junc_Packing_%1", toLower _bodyPart], true, true];

    // If direct pressure over a fracture just roused this otherwise stable casualty, keep the short wake-stimulus
    // grace alive through the packing action. The old 8 s grace expired before this 10 s action completed, which
    // made a casualty visibly wake to pressure and then drop unconscious simply because packing had started.
    private _now = CBA_missionTime;
    private _lastStim = _patient getVariable ["ACME_DP_FracturePainLast", -1e6];
    private _stimPart = toLower (_patient getVariable ["ACME_DP_FracturePainPart", ""]);
    if ((_now - _lastStim) <= 15 && {_stimPart == toLower _bodyPart} && {_patient call ace_common_fnc_isAwake}) then {
        private _stable = !isNil "ace_medical_status_fnc_hasStableVitals" && {[_patient] call ace_medical_status_fnc_hasStableVitals};
        if (_stable) then {
            private _until = (_patient getVariable ["ACME_obtunded_wakeStimGraceUntil", 0]) max (_now + _t + 4);
            _patient setVariable ["ACME_obtunded_wakeStimGraceUntil", _until, true];
        };
    };
};

private _old = _medic getVariable ["ACME_JuncPackSfxSrc", objNull];
if (!isNull _old) then { deleteVehicle _old; };

private _src = createSoundSource ["ACME_JunctionalPackLoop_SoundSource", getPosATL _medic, [], 0];
_src attachTo [_medic, [0, 0, 0]];
_medic setVariable ["ACME_JuncPackSfxSrc", _src];
