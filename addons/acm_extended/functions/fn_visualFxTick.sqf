/*
 * Local-only ACME perception mixer.
 *
 * Physiology contributes continuous magnitudes. Debug actions contribute deterministic local tiers. One controller
 * owns the PP handles so effects cannot fight each other, leak across respawn, or depend on patient-scoped debug vars.
 */
if (!hasInterface) exitWith {};
private _u = player;
if (isNull _u) exitWith {};

private _enabled = missionNamespace getVariable ["ACME_visualFx_enabled",true];
private _epoch = if (!isNil "ACME_fnc_clinicalEpoch") then {[_u] call ACME_fnc_clinicalEpoch} else {0};
private _lastUnit = uiNamespace getVariable ["ACME_VFX_LastUnit",objNull];
private _lastEpoch = uiNamespace getVariable ["ACME_VFX_LastEpoch",-9999];
private _lifeChanged = !(_lastUnit isEqualTo _u) || {_lastEpoch != _epoch};

// The previous implementation created WetDistortion enabled, then tried to neutralize it later in the same tick.
// It also kept debug severity on the casualty object.  Both are bad spawn semantics.  Every new life/clinical epoch
// starts from a hard local zero and ignores physiology for a few seconds while ACE initializes its vital variables.
if (_lifeChanged) then {
    uiNamespace setVariable ["ACME_VFX_LastUnit",_u];
    uiNamespace setVariable ["ACME_VFX_LastEpoch",_epoch];
    uiNamespace setVariable ["ACME_VFX_PhysReadyAt",diag_tickTime + 5.0];
    {
        uiNamespace setVariable [format ["ACME_VFX_Debug_%1",_x],0];
    } forEach ["hypoxia","hypotension","hypercapnia","ketamine","syncope"];
    {
        private _h = uiNamespace getVariable [_x,-1];
        if (_h isEqualType 0 && {_h >= 0}) then {_h ppEffectEnable false;};
    } forEach ["ACME_VFX_Wet","ACME_VFX_KetWetDebug","ACME_VFX_Chrom","ACME_VFX_Blur","ACME_VFX_Color","ACME_VFX_Tunnel"];
    uiNamespace setVariable ["ACME_VFX_WetActive",false];
    uiNamespace setVariable ["ACME_VFX_WetLast",[]];
    uiNamespace setVariable ["ACME_VFX_TunnelLast",[]];
    uiNamespace setVariable ["ACME_VFX_HeartPhase",0];
    uiNamespace setVariable ["ACME_VFX_HeartPhaseAt",diag_tickTime];
    uiNamespace setVariable ["ACME_VFX_ForceRefresh",true];
    uiNamespace setVariable ["ACME_VFX_WetForceRefresh",true];
};
private _physReady = diag_tickTime >= (uiNamespace getVariable ["ACME_VFX_PhysReadyAt",diag_tickTime + 5]);

// Create handles DISABLED. Each effect block below explicitly enables only when its requested magnitude is nonzero.
private _mk = {
    params ["_slot","_name","_prio"];
    private _h = uiNamespace getVariable [_slot,-1];
    if (!(_h isEqualType 0) || {_h < 0}) then {
        private _p = _prio;
        _h = -1;
        while {_h < 0 && {_p < (_prio + 40)}} do {
            _h = ppEffectCreate [_name,_p];
            _p = _p + 1;
        };
        uiNamespace setVariable [_slot,_h];
        if (_h >= 0) then {_h ppEffectEnable false;};
    };
    _h
};
private _wet = ["ACME_VFX_Wet","WetDistortion",330] call _mk;
// Dedicated debug-ketamine wet pass. It is deliberately later than DynamicBlur so Moderate/Severe blur cannot
// visually wash out the displacement. This handle is local, starts disabled, and is asserted while any ketamine
// debug tier is active.
private _ketWetDebugHandle = ["ACME_VFX_KetWetDebug","WetDistortion",480] call _mk;
private _chrom = ["ACME_VFX_Chrom","ChromAberration",230] call _mk;
private _blur = ["ACME_VFX_Blur","DynamicBlur",430] call _mk;
private _color = ["ACME_VFX_Color","ColorCorrections",1530] call _mk;
// Same radial geometry ACM uses for the severe low-oxygen/pneumothorax tunnel, but with an independent handle.
private _tunnel = ["ACME_VFX_Tunnel","ColorCorrections",1531] call _mk;

private _commit = missionNamespace getVariable ["ACME_visualFx_commitSec",0.30];
private _clamp = {params ["_v"]; (_v max 0) min 1};
private _dbgLevel = {
    params ["_kind"];
    private _d = uiNamespace getVariable [format ["ACME_VFX_Debug_%1",_kind],0];
    if !(_d isEqualType 0) exitWith {0};
    round ((_d max 0) min 3)
};
private _dbgMag = {params ["_level"]; [0,0.34,0.68,1.00] param [_level,0]};

private _dbgHyp = ["hypoxia"] call _dbgLevel;
private _dbgLow = ["hypotension"] call _dbgLevel;
private _dbgCO2 = ["hypercapnia"] call _dbgLevel;
private _dbgKet = ["ketamine"] call _dbgLevel;
private _dbgSyn = ["syncope"] call _dbgLevel;

private _hyp = 0;
private _low = 0;
private _co2 = 0;
private _ket = 0;
private _syn = 0;

if (_enabled && {alive _u} && {_physReady}) then {
    private _spo2 = _u getVariable ["ace_medical_spo2",100];
    if !(_spo2 isEqualType 0 && {finite _spo2}) then {_spo2 = 100;};
    _hyp = [((missionNamespace getVariable ["ACME_visualFx_hypoxiaStart",95]) - _spo2) /
        (((missionNamespace getVariable ["ACME_visualFx_hypoxiaStart",95]) - (missionNamespace getVariable ["ACME_visualFx_hypoxiaSevere",72])) max 1)] call _clamp;

    if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
        private _bp = [_u] call ace_medical_status_fnc_getBloodPressure;
        private _dia = _bp param [0,80];
        private _sys = _bp param [1,120];
        if (_dia isEqualType 0 && {_sys isEqualType 0} && {finite _dia} && {finite _sys} && {_sys > 0}) then {
            private _map = _dia + ((_sys - _dia) / 3);
            _low = [((missionNamespace getVariable ["ACME_visualFx_mapStart",70]) - _map) /
                (((missionNamespace getVariable ["ACME_visualFx_mapStart",70]) - (missionNamespace getVariable ["ACME_visualFx_mapSevere",35])) max 1)] call _clamp;
        };
    };

    private _cs = _u getVariable ["ACME_circ_State",createHashMap];
    private _pa = if (_cs isEqualType createHashMap) then {_cs getOrDefault ["paCO2",40]} else {40};
    if !(_pa isEqualType 0 && {finite _pa}) then {_pa = 40;};
    _co2 = [(_pa - (missionNamespace getVariable ["ACME_visualFx_co2Start",48])) /
        (((missionNamespace getVariable ["ACME_visualFx_co2Severe",85]) - (missionNamespace getVariable ["ACME_visualFx_co2Start",48])) max 1)] call _clamp;

    if (!isNil "ACME_fnc_ketamineOnBoard") then {
        private _k = [_u] call ACME_fnc_ketamineOnBoard;
        if (_k isEqualType 0 && {finite _k} && {_k > 0}) then {
            _ket = [(_k - (missionNamespace getVariable ["ACME_visualFx_ketamineStart",0.35])) /
                (((missionNamespace getVariable ["ACME_visualFx_ketamineFull",1.15]) - (missionNamespace getVariable ["ACME_visualFx_ketamineStart",0.35])) max 0.01)] call _clamp;
        };
    };
    _syn = ((_low * 0.75) + (_hyp * 0.35)) min 1;
};

if (_enabled && {alive _u}) then {
    _hyp = _hyp max ([_dbgHyp] call _dbgMag);
    _low = _low max ([_dbgLow] call _dbgMag);
    _co2 = _co2 max ([_dbgCO2] call _dbgMag);
    _ket = _ket max ([_dbgKet] call _dbgMag);
    _syn = _syn max ([_dbgSyn] call _dbgMag);
};

if (!_enabled || {!alive _u}) then {
    _hyp = 0; _low = 0; _co2 = 0; _ket = 0; _syn = 0;
    _dbgHyp = 0; _dbgLow = 0; _dbgCO2 = 0; _dbgKet = 0; _dbgSyn = 0;
};

// Deterministic debug profiles. These are intentionally more obvious than the continuous physiologic thresholds so
// an instructor can verify every layer from the medical menu without guessing whether an effect actually changed.
private _ketWetPhys = if (_dbgKet > 0) then {0} else {if (_ket > 0.001) then {0.38 + (0.62 * _ket)} else {0}};
// Debug ketamine owns a dedicated late wet pass below, so do not double-stack it into the shared wet mixer.
private _ketWetDebug = 0;
private _shockWetPhys = if (_low > 0.20) then {linearConversion [0.20,1,_low,0.20,0.88,true]} else {0};
private _shockWetDebug = [0,0.28,0.62,0.96] param [_dbgLow,0];
private _co2WetPhys = if (_co2 > 0.10) then {linearConversion [0.10,1,_co2,0.08,0.42,true]} else {0};
private _co2WetDebug = [0,0.20,0.48,0.78] param [_dbgCO2,0];
private _dist = (_ketWetPhys max _ketWetDebug max _shockWetPhys max _shockWetDebug max _co2WetPhys max _co2WetDebug) min 1;

private _blurV = ((_hyp*0.90)+(_low*0.80)+(_co2*0.70)+(_ket*0.55)+(_syn*1.00)) min 2.6;
private _dbgBlur = ([0,0.32,0.90,1.65] param [_dbgHyp,0])
    max ([0,0.28,0.82,1.55] param [_dbgLow,0])
    max ([0,0.40,1.05,1.80] param [_dbgCO2,0])
    max ([0,0.18,0.45,0.80] param [_dbgKet,0])
    max ([0,0.55,1.35,2.35] param [_dbgSyn,0]);
_blurV = _blurV max _dbgBlur;

private _chromV = ((_ket*0.006)+(_hyp*0.0015)) min 0.010;
_chromV = _chromV max ([0,0.0018,0.0048,0.0090] param [_dbgKet,0]);
private _dark = ((_hyp*0.34)+(_low*0.40)+(_syn*0.45)) min 0.68;
_dark = _dark max ([0,0.08,0.22,0.42] param [_dbgHyp,0])
    max ([0,0.08,0.24,0.46] param [_dbgLow,0])
    max ([0,0.10,0.30,0.56] param [_dbgSyn,0]);
private _sat = (1 - ((_hyp*0.60)+(_low*0.18))) max 0.24;
private _dbgSat = ([1,0.90,0.68,0.42] param [_dbgHyp,1]) min ([1,0.96,0.86,0.72] param [_dbgLow,1]);
_sat = _sat min _dbgSat;

private _tunnelSource = (_syn max _low max (_hyp*0.85));
private _tunnelStart = missionNamespace getVariable ["ACME_visualFx_tunnelStart",0.50];
private _tunnelI = linearConversion [_tunnelStart,1,_tunnelSource,0,1,true];
private _dbgTunnel = ([0,0.00,0.42,0.95] param [_dbgHyp,0])
    max ([0,0.08,0.52,1.00] param [_dbgLow,0])
    max ([0,0.32,0.74,1.00] param [_dbgSyn,0]);
_tunnelI = _tunnelI max _dbgTunnel;

private _forceAll = uiNamespace getVariable ["ACME_VFX_ForceRefresh",false];
if (_forceAll) then {uiNamespace setVariable ["ACME_VFX_ForceRefresh",false];};

// WetDistortion: assert ENABLED every active tick. Do not trust a cached boolean and do not disable/recreate it
// between Mild -> Moderate -> Severe. Only its profile is recommitted when the requested tier/magnitude changes.
if (_wet >= 0) then {
    if (_dist <= 0.001) then {
        _wet ppEffectEnable false;
        uiNamespace setVariable ["ACME_VFX_WetActive",false];
        uiNamespace setVariable ["ACME_VFX_WetLast",[]];
    } else {
        _wet ppEffectEnable true;
        uiNamespace setVariable ["ACME_VFX_WetActive",true];
        private _forceWet = _forceAll || {uiNamespace getVariable ["ACME_VFX_WetForceRefresh",false]};
        if (_forceWet) then {uiNamespace setVariable ["ACME_VFX_WetForceRefresh",false];};

        private _lastWet = uiNamespace getVariable ["ACME_VFX_WetLast",[]];
        private _signature = [_dist,_ket,_low,_co2,_dbgKet,_dbgLow,_dbgCO2];
        private _changed = _forceWet || {!(_lastWet isEqualTo _signature)};
        if (_changed) then {
            private _ketMix = (_ket max 0) min 1;
            private _shockMix = (_low max 0) min 1;
            private _co2Mix = (_co2 max 0) min 1;
            private _speedBias = ((_ketMix * 0.72) + (_shockMix * 0.28) + (_co2Mix * 0.18)) min 1;

            // Explicit debug amplification.  Mild remains obvious; Moderate is ~2.3x the mild wave gain and Severe
            // ~4x. Shock and hypercapnia have their own slower/smaller gains and can combine with ketamine.
            private _ketGain = [1.00,1.35,3.10,5.40] param [_dbgKet,1.00];
            if (_dbgKet <= 0 && {_ket > 0.001}) then {_ketGain = 1.00 + (1.75 * _ket);};
            private _shockGain = [1.00,1.15,1.75,2.55] param [_dbgLow,1.00];
            private _co2Gain = [1.00,1.05,1.35,1.80] param [_dbgCO2,1.00];
            private _waveGain = _ketGain max _shockGain max _co2Gain;
            private _amp = _dist;

            _wet ppEffectAdjust [
                1,
                0.94 + (0.06*_amp),
                0.94 + (0.06*_amp),
                3.00 + (2.25*_speedBias),
                2.65 + (1.95*_speedBias),
                1.95 + (1.75*_speedBias),
                1.45 + (1.50*_speedBias),
                (0.0044 + (0.0034*_amp)) * _waveGain,
                (0.0034 + (0.0028*_amp)) * _waveGain,
                (0.0074 + (0.0072*_amp)) * _waveGain,
                (0.0057 + (0.0057*_amp)) * _waveGain,
                0.50 + (0.42*_amp),
                0.32 + (0.40*_amp),
                9 + (5*_ketMix),
                5.5 + (4.0*_ketMix)
            ];
            _wet ppEffectCommit 0.06;
            uiNamespace setVariable ["ACME_VFX_WetLast",_signature];
        };
    };
};

// Dedicated ketamine debug wet distortion. Explicit profiles avoid tier-to-tier multiplier ambiguity and this
// effect renders after DynamicBlur, making the water displacement remain plainly visible at Moderate and Severe.
if (_ketWetDebugHandle >= 0) then {
    if (_dbgKet <= 0 || {!_enabled} || {!alive _u}) then {
        _ketWetDebugHandle ppEffectEnable false;
        uiNamespace setVariable ["ACME_VFX_KetWetDebugLast",-1];
    } else {
        _ketWetDebugHandle ppEffectEnable true;
        private _lastKetWetTier = uiNamespace getVariable ["ACME_VFX_KetWetDebugLast",-1];
        if (_forceAll || {_lastKetWetTier != _dbgKet}) then {
            private _profile = switch (_dbgKet) do {
                case 1: {[1,1,1,4.35,3.90,2.80,2.10,0.0072,0.0054,0.0160,0.0120,0.56,0.36,10.0,6.0]};
                case 2: {[1,1,1,5.25,4.65,3.55,2.75,0.0115,0.0085,0.0330,0.0245,0.70,0.50,11.2,7.0]};
                case 3: {[1,1,1,6.40,5.55,4.55,3.60,0.0175,0.0130,0.0600,0.0450,0.86,0.66,12.8,8.2]};
                default {[1,1,1,4.10,3.70,2.50,1.85,0.0054,0.0041,0.0090,0.0070,0.50,0.30,10.0,6.0]};
            };
            _ketWetDebugHandle ppEffectAdjust _profile;
            _ketWetDebugHandle ppEffectCommit 0.08;
            uiNamespace setVariable ["ACME_VFX_KetWetDebugLast",_dbgKet];
        };
        // Do not trust cached PP state. Reassert enable every controller tick for the full non-zero debug cycle.
        _ketWetDebugHandle ppEffectEnable true;
    };
};

// HR-synchronous ACM-style radial tunnel. The geometry remains recognizable as ACM's low-oxygen tunnel but the
// pulse cadence follows actual HR so shock/hypoxia is visibly different from the fixed pneumothorax cadence.
if (_tunnel >= 0) then {
    if (_tunnelI <= 0.001) then {
        _tunnel ppEffectEnable false;
        uiNamespace setVariable ["ACME_VFX_TunnelLast",[]];
        uiNamespace setVariable ["ACME_VFX_HeartPhase",0];
        uiNamespace setVariable ["ACME_VFX_HeartPhaseAt",diag_tickTime];
    } else {
        _tunnel ppEffectEnable true;
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

        private _beatPulse = if (_heartPhase < 0.30) then {1 - (_heartPhase / 0.30)} else {0};
        private _pulseI = (_tunnelI * (0.72 + (0.28 * _beatPulse))) min 1;
        private _tv = 0.6 * _pulseI;
        private _blendA = _pulseI * (0.95 + (0.05 * _beatPulse));
        private _tone = 0.10 - (0.09 * _beatPulse);
        private _radA = (0.85 - (0.10 * _beatPulse)) - _tv;
        private _radB = (0.80 - (0.10 * _beatPulse)) - _tv;
        private _adjust = [1,1,0,[0,0,0,_blendA],[_tone,_tone,_tone,_tone],[0,0,0,0],[_radA,_radB,0,0,0,0,8]];

        private _last = uiNamespace getVariable ["ACME_VFX_TunnelLast",[]];
        private _signature = [round (_tunnelI*100),round (_beatPulse*100),round _hr];
        if (_forceAll || {!(_last isEqualTo _signature)}) then {
            _tunnel ppEffectAdjust _adjust;
            _tunnel ppEffectCommit 0.04;
            uiNamespace setVariable ["ACME_VFX_TunnelLast",_signature];
        };
    };
};

if (_chrom >= 0) then {
    if (_chromV <= 0.00005) then {_chrom ppEffectEnable false;} else {
        _chrom ppEffectEnable true;
        _chrom ppEffectAdjust [_chromV,_chromV*0.65,true];
        _chrom ppEffectCommit _commit;
    };
};
if (_blur >= 0) then {
    if (_blurV <= 0.01) then {_blur ppEffectEnable false;} else {
        _blur ppEffectEnable true;
        _blur ppEffectAdjust [_blurV];
        _blur ppEffectCommit _commit;
    };
};
if (_color >= 0) then {
    private _colorActive = _dark > 0.005 || {_sat < 0.995};
    if (!_colorActive) then {_color ppEffectEnable false;} else {
        _color ppEffectEnable true;
        _color ppEffectAdjust [1-_dark,1+(_syn*0.08),0,[0,0,0,0],[1,1,1,_sat],[0.299,0.587,0.114,0],[-1,-1,0,0,0,0,0]];
        _color ppEffectCommit _commit;
    };
};
