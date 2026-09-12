// the shared blast solver. one pressure calculation, and everything downstream reads its answer.
// call it as [_unit, _ammo, _detPos, _engineDamage] call ACME_fnc_blastSolve, which returns a hashmap.
// _unit is the exposed man. _ammo is the ammo classname, or "" if unknown. _detPos is the detonation position in
// ASL, or [] if unknown. _engineDamage is the damage the engine reported at this unit, from the Explosion event
// handler, and it is the fallback when the position is unknown.
//
// why one solver.
// the injury systems used to each roll their own chance off the engine damage number. that meant a blast could
// give a TBI and no lung injury, or the reverse, for reasons that had nothing to do with the blast: two separate
// rolls off the same input. a casualty is exposed to one pressure wave, so there is one dose, and every
// consequence is a threshold on it. that is also what makes the picture readable to a medic, because the
// findings agree with each other and with what they saw happen.
//
// the returned hashmap.
//   "psoKpa"    peak incident overpressure at the unit, in kPa.
//   "prKpa"     effective peak pressure after reflection and enclosure, in kPa. this is the injury number.
//   "durMs"     positive phase duration, in ms.
//   "impulse"   positive phase impulse, in kPa times ms. this is what matters at close range.
//   "wKg"       the TNT equivalent used, in kg.
//   "rangeM"    the range used, in m.
//   "encl"      the enclosure multiplier that was applied.
//   "los"       true if the unit had direct line of sight to the detonation.
//   "dose"      0 to 1. the single normalized number the effects read.
//
// what the numbers are.
// the overpressure curve is Sadovsky, which is the standard scaled-distance form: with Z as the scaled distance
// R over the cube root of W, the peak incident overpressure in MPa is 0.085/Z + 0.3/Z^2 + 0.8/Z^3. it is valid
// for roughly 1 < Z < 15 and it is the same relation used to size blast walls, so the thresholds below sit where
// the literature puts them rather than where they felt right.
// the reflection is the normal-reflection relation, Pr = 2*Pso*(7*P0 + 4*Pso)/(7*P0 + Pso) with P0 at 101.3 kPa
// atmospheric. it is why a small charge in a room is so much worse than the same charge in the open: at low
// overpressure the reflected wave is about twice the incident, and as the incident climbs it approaches eight
// times.
// the anchors the dose is scaled against are the published injury thresholds.
//   about 35 kPa   the threshold for eardrum rupture.
//   about 100 kPa  50 percent eardrum rupture.
//   about 200 kPa  the threshold for lung injury, which is where blast lung starts.
//   about 550 kPa  roughly 50 percent lethality from the pressure alone.
// so a dose of 1.0 is a wave that would kill about half the people standing in it. everything below that is
// survivable and treatable, which is the part worth simulating.
params ["_unit", ["_ammo", ""], ["_detPos", []], ["_engineDamage", 0]];
if (isNull _unit) exitWith { createHashMap };
// the system toggle. an empty hashmap means no dose, and fn_blastapply exits on it, so every caller stops
// cleanly without needing to know about the setting.
if !(missionNamespace getVariable ["ACME_sys_blastOverpressure", false]) exitWith { createHashMap };

private _P0 = 101.3;  // atmospheric pressure at sea level, in kPa. it is the reference for the reflection term.

// 1. the charge.
// arma does not tell us how much explosive was in the thing that went off, so it is estimated from the two config
// entries that describe the blast: indirecthit, the damage at the center, and indirecthitrange, how far it
// carries. the coefficient is tuned so a fragmentation grenade lands near 0.18 kg, which is what an M67 holds.
// a mission or a mod can override any ammo directly through ACME_blast_tntOverride, a hashmap of classname to kg,
// which is the escape hatch for anything the estimate gets badly wrong.
private _wKg = 0;
private _iHit = 0;
private _iRange = 0;
if (_ammo != "") then {
    private _cfg = configFile >> "CfgAmmo" >> _ammo;
    if (isClass _cfg) then {
        _iHit   = getNumber (_cfg >> "indirectHit");
        _iRange = getNumber (_cfg >> "indirectHitRange");
        private _ovr = missionNamespace getVariable ["ACME_blast_tntOverride", createHashMap];
        _wKg = _ovr getOrDefault [_ammo, 0];
        if (_wKg <= 0) then {
            _wKg = _iHit * (missionNamespace getVariable ["ACME_blast_tntPerIndirectHit", 0.005]);
        };
    };
};
// nothing usable in config, so fall back to a hand grenade rather than returning nothing. a blast we cannot
// identify is still a blast, and under-calling it to zero would silently disable the whole system for any modded
// ordnance with an unusual config.
if (_wKg <= 0) then { _wKg = 0.18 };

// 2. the range.
// with a detonation position we measure it. without one, the engine damage is inverted through arma's own linear
// falloff, damage is indirecthit scaled down across indirecthitrange, which is an approximation and is documented
// as one. it is only used when the position is genuinely unavailable.
private _rangeM = -1;
if ((count _detPos) >= 3) then {
    _rangeM = _detPos distance (getPosASL _unit);
} else {
    if (_iHit > 0 && {_iRange > 0} && {_engineDamage > 0}) then {
        _rangeM = _iRange * (1 - ((_engineDamage / _iHit) min 1));
    };
};
// no position and no usable config means there is nothing to build a range out of.
// this used to fall through to the floor below and every such blast was treated as a grenade going off half a
// meter away, which is about 1600 kPa and kills instantly. a missing input became the most severe possible
// answer, which is the wrong direction for a guess to fail in.
// so the pressure model is abandoned for this case and the engine damage is used directly as a crude dose proxy.
// it is marked so callers can tell a real solve from an estimate, and it is deliberately conservative.
if (_rangeM < 0) exitWith {
    private _d = (_engineDamage max 0) min 1;
    private _pr = _d * (missionNamespace getVariable ["ACME_blast_lethalKpa", 550]);
    private _o = createHashMap;
    _o set ["psoKpa", _pr]; _o set ["prKpa", _pr]; _o set ["durMs", 3];
    _o set ["impulse", 0.5 * _pr * 3]; _o set ["wKg", _wKg]; _o set ["rangeM", -1];
    _o set ["encl", 1]; _o set ["los", true]; _o set ["dose", (_d min 2)];
    _o set ["estimated", true];
    if (_d > 0) then {
        private _prev2 = _unit getVariable ["ACME_blast_cumulative", 0];
        [_unit, "ACME_blast_cumulative", ((_prev2 + _d) min 5)] call ACME_fnc_setVarNet;
        [_unit, "ACME_blast_lastTime", CBA_missionTime] call ACME_fnc_setVarNet;
    };
    _o
};

// a floor on the range. the scaled-distance relation runs away to infinity at zero and a casualty standing on the
// charge is a fragmentation and thermal problem rather than an overpressure one, which is calculated separately.
if (_rangeM < 0.5) then { _rangeM = 0.5 };

// 3. the free-field wave.
private _cubeRoot = _wKg ^ (1/3);
private _Z = _rangeM / _cubeRoot;
if (_Z < 0.05) then { _Z = 0.05 };
private _psoMpa = (0.085 / _Z) + (0.3 / (_Z ^ 2)) + (0.8 / (_Z ^ 3));
private _psoKpa = _psoMpa * 1000;

// the positive phase duration, in ms. it grows with charge size and with distance, which is why a large charge
// far away can carry more impulse than a small one close, even at a lower peak.
private _durMs = 1.8 * _cubeRoot * (_Z ^ 0.5);
if (_durMs < 0.2) then { _durMs = 0.2 };

// 4. line of sight, cover and orientation.
// cover stops fragments and it does not stop pressure. a wall between the casualty and the charge diffracts the
// wave around itself and attenuates it, and the casualty still gets a dose. so this is a multiplier and never a
// block, which is the single most important distinction in the whole model.
private _los = true;
if ((count _detPos) >= 3) then {
    private _eye = (getPosASL _unit) vectorAdd [0, 0, 1.2];
    private _hits = lineIntersectsSurfaces [_detPos, _eye, objNull, _unit, true, 1];
    _los = (count _hits) == 0;
};
private _coverMul = if (_los) then {1} else {
    missionNamespace getVariable ["ACME_blast_coverAtten", 0.55]
};

// orientation. a body side-on presents less area to the wave than one facing it or backing it. the effect is real
// and it is small, so it is a light multiplier rather than a headline factor.
private _orientMul = 1;
if ((count _detPos) >= 3) then {
    private _toBlast = [(_detPos select 0) - (getPosASL _unit select 0), (_detPos select 1) - (getPosASL _unit select 1), 0];
    private _facing = vectorDir _unit;
    private _dot = abs (((vectorNormalized _toBlast) select 0) * (_facing select 0) + ((vectorNormalized _toBlast) select 1) * (_facing select 1));
    // _dot is 1 facing straight at or away from it, and 0 side-on.
    _orientMul = linearConversion [0, 1, _dot, (missionNamespace getVariable ["ACME_blast_orientSideOn", 0.85]), 1, true];
};

// 5. enclosure and reflection.
// this is the part that makes a small charge indoors so dangerous. in the open the wave passes and is gone. in a
// room it reflects off the walls, the floor and the ceiling, and the casualty is hit repeatedly by a wave that has
// nowhere to go.
// the test is deliberately cheap: a roof overhead plus nearby vertical surfaces. it is not ray-traced acoustics
// and it does not need to be, because the difference being modeled is order-of-magnitude rather than subtle.
private _encl = 1;
private _posA = getPosASL _unit;
private _roof = (count (lineIntersectsSurfaces [_posA vectorAdd [0,0,1.5], _posA vectorAdd [0,0,12], _unit, objNull, true, 1])) > 0;
if (_roof || {!(isNull objectParent _unit)}) then {
    private _walls = 0;
    {
        private _dir = _x;
        private _to = _posA vectorAdd [(sin _dir) * 6, (cos _dir) * 6, 0.5];
        if ((count (lineIntersectsSurfaces [_posA vectorAdd [0,0,0.5], _to, _unit, objNull, true, 1])) > 0) then {
            _walls = _walls + 1;
        };
    } forEach [0, 90, 180, 270];
    // a vehicle interior is the worst case of all: a small sealed volume with hard surfaces on every side.
    if (!(isNull objectParent _unit)) then { _walls = 4 };
    // the reflected pressure of the normal-reflection relation, blended in by how enclosed the space is. one wall
    // and a roof is a doorway and barely counts. four walls and a roof is a room.
    private _prFull = 2 * _psoKpa * ((7 * _P0 + 4 * _psoKpa) / (7 * _P0 + _psoKpa));
    private _blend = (_walls / 4) * (missionNamespace getVariable ["ACME_blast_enclosureMax", 1.0]);
    _encl = 1 + (((_prFull / (_psoKpa max 0.001)) - 1) * _blend);
};

// 6. the effective pressure the body actually sees.
private _prKpa = _psoKpa * _coverMul * _orientMul * _encl;
private _impulse = 0.5 * _prKpa * _durMs;

// 7. the dose, and the exposure history.
// the dose is scaled against the 50 percent lethality anchor, so 1.0 is a wave that kills about half the people
// standing in it.
private _lethal = missionNamespace getVariable ["ACME_blast_lethalKpa", 550];
private _dose = (_prKpa / _lethal) min 2;

// repeated exposure accumulates. a casualty who has been in three blasts today is not the same casualty as one who
// has been in their first, and this is exactly what the mild TBI literature is about. the accumulated total decays
// over hours, so it is not permanent, and it does not reset on a bandage.
private _prev = _unit getVariable ["ACME_blast_cumulative", 0];
private _lastT = _unit getVariable ["ACME_blast_lastTime", -99999];
private _halfLife = missionNamespace getVariable ["ACME_blast_cumulativeHalfLife", 3600];
private _decayed = _prev * (2 ^ (-((CBA_missionTime - _lastT) max 0) / _halfLife));
[_unit, "ACME_blast_cumulative", ((_decayed + _dose) min 5)] call ACME_fnc_setVarNet;
[_unit, "ACME_blast_lastTime", CBA_missionTime] call ACME_fnc_setVarNet;

// the exposure record, for the aar and for anything that wants to ask what happened rather than only what is
// wrong now. it is capped so a long mission cannot grow it without bound.
private _hist = _unit getVariable ["ACME_blast_history", []];
_hist pushBack [round CBA_missionTime, round _prKpa, round _impulse, _ammo];
if ((count _hist) > 20) then { _hist deleteAt 0 };
_unit setVariable ["ACME_blast_history", _hist, true];

private _out = createHashMap;
_out set ["psoKpa", _psoKpa];
_out set ["prKpa", _prKpa];
_out set ["durMs", _durMs];
_out set ["impulse", _impulse];
_out set ["wKg", _wKg];
_out set ["rangeM", _rangeM];
_out set ["encl", _encl];
_out set ["los", _los];
_out set ["dose", _dose];
_out set ["estimated", false];
_out
