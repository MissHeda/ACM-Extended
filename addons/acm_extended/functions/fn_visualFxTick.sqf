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
private _commit = missionNamespace getVariable ["ACME_visualFx_commitSec",0.30];
private _clamp = {params ["_v"]; (_v max 0) min 1};
private _dbg = {params ["_kind"]; private _d = _u getVariable [format ["ACME_visualFxDebug_%1",_kind],0]; [0,0.28,0.58,0.90] param [_d,0]};
private _hyp=0; private _low=0; private _co2=0; private _ket=0; private _syn=0;
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
private _dist = ((_ket*0.85)+(_co2*0.30)) min 1;
private _blurV = ((_hyp*0.9)+(_low*0.8)+(_co2*0.7)+(_ket*0.55)+(_syn*1.0)) min 2.6;
private _chromV = ((_ket*0.006)+(_hyp*0.0015)) min 0.008;
private _dark = ((_hyp*0.34)+(_low*0.40)+(_syn*0.45)) min 0.62;
private _sat = (1 - ((_hyp*0.60)+(_low*0.18))) max 0.28;
if (_wet >= 0) then {
    // WetDistortion has no useful neutral parameter set for this profile: the old "zero" state still had
    // non-zero wave amplitudes/frequencies and therefore made every healthy player spawn with swimming vision.
    // Keep the effect completely disabled until an actual distortion source is present.
    if (_dist <= 0.001) then {
        _wet ppEffectEnable false;
    } else {
        _wet ppEffectEnable true;
        _wet ppEffectAdjust [1,1,1,1.2+2.3*_dist,1.0+2.1*_dist,0.8+1.7*_dist,0.65+1.4*_dist,0.001+0.005*_dist,0.001+0.004*_dist,0.0015+0.008*_dist,0.001+0.006*_dist,0.25+0.55*_dist,0.2+0.45*_dist,4+6*_dist,3+4*_dist];
        _wet ppEffectCommit _commit;
    };
};
if (_chrom >= 0) then {_chrom ppEffectAdjust [_chromV,_chromV*0.65,true]; _chrom ppEffectCommit _commit;};
if (_blur >= 0) then {_blur ppEffectAdjust [_blurV]; _blur ppEffectCommit _commit;};
if (_color >= 0) then {_color ppEffectAdjust [1-_dark,1+(_syn*0.08),0,[0,0,0,0],[1,1,1,_sat],[0.299,0.587,0.114,0],[-1,-1,0,0,0,0,0]]; _color ppEffectCommit _commit;};
