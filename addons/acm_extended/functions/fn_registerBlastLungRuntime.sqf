/*
 * Phase 23 runtime ownership: Blast-lung wound intake event registration.
 *
 * Extracted intact from ACME_fnc_postInit. The helper is invoked synchronously at the
 * original registration point so CBA handler/PFH order is unchanged.
 */

["ace_medical_woundReceived", {
    params ["_unit", "_allDamages", "_shooter", "_ammo"];
    if (isNull _unit || {!alive _unit} || {!local _unit}) exitWith {};
    if (!(missionNamespace getVariable ["ACME_blastLung_enabled", true])) exitWith {};
    if (isNil "ace_medical_damage_fnc_getTypeOfDamage") exitWith {};
    private _type = _ammo call ace_medical_damage_fnc_getTypeOfDamage;
    // blast types only. a bullet or a stab does not cause a primary blast injury.
    if !(_type in ["explosive", "grenade", "vehiclehit", "shell", "bomb"]) exitWith {};
    // the overpressure has to genuinely load the chest. the threshold is high on purpose, because a routine frag
    // hit to the torso is not blast lung. only a casualty who took a serious blast to the chest is a candidate.
    private _torso = 0;
    {
        _x params [["_dmg", 0], ["_part", ""]];
        if (_part in ["Body", "Chest", "Torso"]) then { _torso = _torso max _dmg; };
    } forEach _allDamages;
    private _minDmg = missionNamespace getVariable ["ACME_blastLung_minTorsoDamage", 0.55];
    if (_torso < _minDmg) exitWith {};

    // every qualifying blast is logged, whether or not it causes the injury. a lung already shaken by
    // overpressure is more vulnerable to the next one.
    private _exposures = _unit getVariable ["ACME_blastLung_exposures", 0];
    [_unit, _exposures + 1, "KEEP", "KEEP", true] call ACME_fnc_blastLungEpisodeCommit;

    // rare. 1 percent at the threshold, up to 10 percent for a maximal blast load on the chest, and scaled up by
    // prior exposures.
    private _minC = missionNamespace getVariable ["ACME_blastLung_chanceMin", 0.01];
    private _maxC = missionNamespace getVariable ["ACME_blastLung_chanceMax", 0.10];
    private _base = linearConversion [_minDmg, 1.0, _torso, _minC, _maxC, true];
    private _repeatMult = 1 + ((_exposures min 4) * (missionNamespace getVariable ["ACME_blastLung_repeatMult", 0.4]));
    private _chance = (_base * _repeatMult) min (missionNamespace getVariable ["ACME_blastLung_chanceCap", 0.30]);
    if ((random 1) >= _chance) exitWith {};

    // if it does land, it is serious. the severity scales with the blast load on the chest.
    private _sev = linearConversion [_minDmg, 1.0, _torso, 0.35, 0.90, true];
    [_unit, _sev] call ACME_fnc_blastLungInflict;
}] call CBA_fnc_addEventHandler;
