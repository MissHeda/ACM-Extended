/* Local-only PP mixer. Physiology and instructor overrides contribute magnitudes; one controller owns the PP handles. */
if (!hasInterface) exitWith {};
private _u = player;
if (isNull _u) exitWith {};
private _enabled = missionNamespace getVariable ["ACME_visualFx_enabled",true];
// ACE medical values can be transiently uninitialized when a player first spawns or changes controlled unit.
// Hold physiology-driven FX briefly, but still allow instructor/debug overrides below.
private _lastUnit = uiNamespace getVariable ["ACME_VFX_LastUnit",objNull];
if !(_lastUnit isEqualTo _u) then {
    uiNamespace setVariable ["ACME_VFX_LastUnit",_u];
    uiNamespace setVariable ["ACME_VFX_PhysReadyAt",diag_tickTime + 2.5];
};
private _physReady = diag_tickTime >= (uiNamespace getVariable ["ACME_VFX_PhysReadyAt",0]);
private _mk = {
    params ["_slot","_name","_prio"];
    private _h = uiNamespace getVariable [_slot,-1];
    if (!(_h isEqualType 0) || {_h < 0}) then {
        private _p = _prio; _h = -1;
        while {_h < 0 && {_p < (_prio + 40)}} do {_h = ppEffectCreate [_name,_p]; _p = _p + 1;};
        uiNamespace setVariable [_slot,_h];
        if (_h >= 0) then {_h ppEffectEnable true;};
    };
    _h
};
private _wet = ["ACME_VFX_Wet","WetDistortion",330] call _mk;
private _chrom = ["ACME_VFX_Chrom","ChromAberration",230] call _mk;
private _blur = ["ACME_VFX_Blur","DynamicBlur",430] call _mk;
private _color = ["ACME_VFX_Color","ColorCorrections",1530] call _mk;
// Same radial ColorCorrections profile ACM uses for severe low-oxygen/pneumothorax tunnel vision.
// Keep a separate handle so ACME never takes ownership of ACM's ppLowOxygenTunnelVision handle.
private _tunnel = ["ACME_VFX_Tunnel","ColorCorrections",1531] call _mk;
private _commit = missionNamespace getVariable ["ACME_visualFx_commitSec",0.30];
private _clamp = {params ["_v"]; (_v max 0) min 1};
private _dbg = {
    params ["_kind"];
    private _d = _u getVariable [format ["ACME_visualFxDebug_%1",_kind],0];
    [0,0.32,0.66,1.00] param [_d,0]
};
private _hyp=0; private _low=0; private _co2=0; private _ket=0; private _syn=0;
private _ketDebugLevel = if (alive _u) then {(_u getVariable ["ACME_visualFxDebug_ketamine",0]) max 0 min 3} else {0};
if (_enabled && {alive _u} && {_physReady}) then {
    private _spo2 = _u getVariable ["ace_medical_spo2",100];
    _hyp = [((missionNamespace getVariable ["ACME_visualFx_hypoxiaStart",95]) - _spo2) / (((missionNamespace getVariable ["ACME_visualFx_hypoxiaStart",95]) - (missionNamespace getVariable ["ACME_visualFx_hypoxiaSevere",72])) max 1)] call _clamp;
    if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
        private _bp = [_u] call ace_medical_status_fnc_getBloodPressure; private _dia=_bp param [0,80]; private _sys=_bp param [1,120]; private _map=_dia + ((_sys-_dia)/3);
        _low = [((missionNamespace getVariable ["ACME_visualFx_mapStart",70]) - _map) / (((missionNamespace getVariable ["ACME_visualFx_mapStart",70]) - (missionNamespace getVariable ["ACME_visualFx_mapSevere",35])) max 1)] call _clamp;
    };
    private _cs = _u getVariable ["ACME_circ_State",createHashMap]; private _pa = _cs getOrDefault ["paCO2",40];
    _co2 = [(_pa - (missionNamespace getVariable ["ACME_visualFx_co2Start",48])) / (((missionNamespace getVariable ["ACME_visualFx_co2Severe",85]) - (missionNamespace getVariable ["ACME_visualFx_co2Start",48])) max 1)] call _clamp;
    if (!isNil "ACME_fnc_ketamineOnBoard") then {private _k=[_u] call ACME_fnc_ketamineOnBoard; _ket=[(_k-(missionNamespace getVariable ["ACME_visualFx_ketamineStart",0.35]))/(((missionNamespace getVariable ["ACME_visualFx_ketamineFull",1.15])-(missionNamespace getVariable ["ACME_visualFx_ketamineStart",0.35])) max 0.01)] call _clamp;};
    _syn = ((_low*0.75)+(_hyp*0.35)) min 1;
};
if (alive _u) then {_hyp = _hyp max (["hypoxia"] call _dbg); _low = _low max (["hypotension"] call _dbg); _co2 = _co2 max (["hypercapnia"] call _dbg); _ket = _ket max (["ketamine"] call _dbg); _syn = _syn max (["syncope"] call _dbg);};
// Perceptual warping is deliberately shared by dissociation and hemodynamic collapse. Ketamine gets a
// persistent water-distortion floor at every non-zero level, so cycling Mild -> Moderate -> Severe can never
// accidentally lose the WetDistortion layer. Shock becomes watery once it is clinically meaningful; hypercapnia
// stays a smaller contributor. Hypoxia itself does not create water distortion.
// Debug ketamine is intentionally tiered instead of being inferred only from the generic 0..1 mixer.
// This makes every non-zero cycle an explicit WetDistortion state and gives Moderate/Severe materially
// stronger wave profiles instead of simply adding blur/chromatic aberration.
private _ketWetPhys = if (_ket > 0.001) then {0.42 + (0.58 * _ket)} else {0};
private _ketWetDebug = [0,0.58,0.82,1.00] param [_ketDebugLevel,0];
private _ketWet = _ketWetPhys max _ketWetDebug;
private _shockWet = if (_low > 0.20) then {linearConversion [0.20,1,_low,0.22,0.88,true]} else {0};
private _co2Wet = if (_co2 > 0.10) then {linearConversion [0.10,1,_co2,0.08,0.42,true]} else {0};
private _dist = (_ketWet max _shockWet max _co2Wet) min 1;
private _blurV = ((_hyp*0.9)+(_low*0.8)+(_co2*0.7)+(_ket*0.55)+(_syn*1.0)) min 2.6;
private _chromV = ((_ket*0.006)+(_hyp*0.0015)) min 0.008;
private _dark = ((_hyp*0.34)+(_low*0.40)+(_syn*0.45)) min 0.62;
private _sat = (1 - ((_hyp*0.60)+(_low*0.18))) max 0.28;

// ACM's severe pneumothorax/low-oxygen effect begins to close the visual field as the condition crosses into the
// severe range.  ACME reuses that exact radial ColorCorrections shape for severe shock/hypoxia/near-syncope, but
// owns a different PP handle so the two systems never overwrite one another. Moderate debug (0.66) is already
// inside the tunnel range and Severe (1.00) reaches the full ACME profile.
private _tunnelSource = (_syn max _low max (_hyp*0.85));
private _tunnelStart = missionNamespace getVariable ["ACME_visualFx_tunnelStart",0.50];
private _tunnelI = linearConversion [_tunnelStart,1,_tunnelSource,0,1,true];

if (_wet >= 0) then {
    // B128: do not recommit WetDistortion every 50 ms. Repeated commits can keep restarting the effect's
    // interpolation/phase on some clients, which made the first Mild ketamine pulse visible and later cycle levels
    // appear to lose the water motion. Enable once, update only when the requested profile changes, and let the
    // engine's wave phase continue running between updates.
    private _wasWet = uiNamespace getVariable ["ACME_VFX_WetActive",false];
    if (_dist <= 0.001) then {
        if (_wasWet) then {_wet ppEffectEnable false;};
        uiNamespace setVariable ["ACME_VFX_WetActive",false];
        uiNamespace setVariable ["ACME_VFX_WetLast",[-1,-1,-1,-1,-1]];
    } else {
        // Never trust only our cached flag: another script/engine transition can leave the handle present but
        // disabled. Any active ketamine/shock/CO2 source continuously asserts that WetDistortion stays enabled.
        if (!_wasWet || {!(ppEffectEnabled _wet)}) then {
            _wet ppEffectEnable true;
            uiNamespace setVariable ["ACME_VFX_WetActive",true];
            uiNamespace setVariable ["ACME_VFX_WetLast",[-1,-1,-1,-1,-1]];
        };

        private _forceWetRefresh = uiNamespace getVariable ["ACME_VFX_WetForceRefresh",false];
        if (_forceWetRefresh) then {uiNamespace setVariable ["ACME_VFX_WetForceRefresh",false];};
        private _lastWet = uiNamespace getVariable ["ACME_VFX_WetLast",[-1,-1,-1,-1,-1]];
        private _changed = _forceWetRefresh
            || {abs ((_lastWet param [0,-1]) - _dist) >= 0.015}
            || {abs ((_lastWet param [1,-1]) - _ket) >= 0.015}
            || {abs ((_lastWet param [2,-1]) - _low) >= 0.015}
            || {abs ((_lastWet param [3,-1]) - _co2) >= 0.015}
            || {(_lastWet param [4,-1]) != _ketDebugLevel};
        if (_changed) then {
            // Mild stays clearly watery. Moderate and Severe deliberately amplify the four wave amplitudes
            // well beyond the default WetDistortion profile while retaining continuous phase motion.
            private _ketMix = _ket max 0 min 1;
            private _shockMix = _low max 0 min 1;
            private _speedBias = ((_ketMix * 0.70) + (_shockMix * 0.25) + (_co2 * 0.12)) min 1;
            private _amp = _dist;
            private _ketWaveGain = [1.00,1.15,1.85,2.80] param [_ketDebugLevel,1.00];
            // Physiologic ketamine without a debug override still scales smoothly up to a strong dissociative wave.
            if (_ketDebugLevel <= 0 && {_ket > 0.001}) then {_ketWaveGain = 1.00 + (1.35 * _ket);};
            private _waveGain = _ketWaveGain max (1.00 + (0.55 * _shockMix));
            _wet ppEffectAdjust [
                1,
                0.94 + (0.06*_amp),
                0.94 + (0.06*_amp),
                3.10 + (1.80*_speedBias),
                2.75 + (1.55*_speedBias),
                2.05 + (1.45*_speedBias),
                1.55 + (1.20*_speedBias),
                (0.0042 + (0.0030*_amp)) * _waveGain,
                (0.0032 + (0.0024*_amp)) * _waveGain,
                (0.0070 + (0.0065*_amp)) * _waveGain,
                (0.0054 + (0.0050*_amp)) * _waveGain,
                0.50 + (0.40*_amp),
                0.32 + (0.38*_amp),
                9 + (4*_ketMix),
                5.5 + (3.5*_ketMix)
            ];
            // A short commit changes strength without repeatedly restarting the wave every controller tick.
            _wet ppEffectCommit ([0.04,0.10] select _wasWet);
            uiNamespace setVariable ["ACME_VFX_WetLast",[_dist,_ket,_low,_co2,_ketDebugLevel]];
        };
    };
};

if (_tunnel >= 0) then {
    if (_tunnelI <= 0.001) then {
        _tunnel ppEffectEnable false;
        uiNamespace setVariable ["ACME_VFX_TunnelLast",[-1,-1,-1]];
        uiNamespace setVariable ["ACME_VFX_HeartPhase",0];
        uiNamespace setVariable ["ACME_VFX_HeartPhaseAt",diag_tickTime];
    } else {
        _tunnel ppEffectEnable true;

        // B128: use ACM's severe low-oxygen/pneumothorax radial endpoints, but drive the interpolation with the
        // casualty's actual heart rate instead of ACM's fixed two-second pulse. The phase integrates over time so
        // changing HR alters cadence smoothly rather than resetting the pulse clock.
        private _hr = _u getVariable ["ace_medical_heartRate",80];
        if (!(_hr isEqualType 0) || {!finite _hr}) then {_hr = 80;};
        _hr = (_hr max 25) min 240;
        private _rr = 60 / _hr;
        private _lastPulseAt = uiNamespace getVariable ["ACME_VFX_HeartPhaseAt",diag_tickTime];
        private _pulseDt = ((diag_tickTime - _lastPulseAt) max 0) min 0.25;
        private _heartPhase = uiNamespace getVariable ["ACME_VFX_HeartPhase",0];
        _heartPhase = (_heartPhase + (_pulseDt / (_rr max 0.10))) mod 1;
        uiNamespace setVariable ["ACME_VFX_HeartPhase",_heartPhase];
        uiNamespace setVariable ["ACME_VFX_HeartPhaseAt",diag_tickTime];

        // Systolic contraction: a sharp vignette closure at the beat, relaxing over the first ~30% of each R-R.
        private _beatPulse = if (_heartPhase < 0.30) then {1 - (_heartPhase / 0.30)} else {0};
        private _pulseI = (_tunnelI * (0.72 + (0.28 * _beatPulse))) min 1;
        private _tv = 0.6 * _pulseI;
        // These are a continuous interpolation between ACM's exact initial and delayed tunnel profiles:
        // initial radial 0.85/0.80 + color 0.10, delayed radial 0.75/0.70 + color 0.01.
        private _blendA = _pulseI * (0.95 + (0.05 * _beatPulse));
        private _tone = 0.10 - (0.09 * _beatPulse);
        private _radA = (0.85 - (0.10 * _beatPulse)) - _tv;
        private _radB = (0.80 - (0.10 * _beatPulse)) - _tv;
        private _adjust = [1,1,0,[0,0,0,_blendA],[_tone,_tone,_tone,_tone],[0,0,0,0],[_radA,_radB,0,0,0,0,8]];

        private _last = uiNamespace getVariable ["ACME_VFX_TunnelLast",[-1,-1,-1]];
        private _lastI = _last param [0,-1];
        private _lastPulse = _last param [1,-1];
        private _lastHR = _last param [2,-1];
        if (abs (_lastI - _tunnelI) >= 0.01 || {abs (_lastPulse - _beatPulse) >= 0.03} || {abs (_lastHR - _hr) >= 1}) then {
            _tunnel ppEffectAdjust _adjust;
            _tunnel ppEffectCommit 0.04;
            uiNamespace setVariable ["ACME_VFX_TunnelLast",[_tunnelI,_beatPulse,_hr]];
        };
    };
};

if (_chrom >= 0) then {_chrom ppEffectAdjust [_chromV,_chromV*0.65,true]; _chrom ppEffectCommit _commit;};
if (_blur >= 0) then {_blur ppEffectAdjust [_blurV]; _blur ppEffectCommit _commit;};
if (_color >= 0) then {_color ppEffectAdjust [1-_dark,1+(_syn*0.08),0,[0,0,0,0],[1,1,1,_sat],[0.299,0.587,0.114,0],[-1,-1,0,0,0,0,0]]; _color ppEffectCommit _commit;};
