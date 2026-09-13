#include "..\script_component.hpp"
/*
 * Builds a deterministic multi-bandage plan against a copy of the current open wounds.
 * Priority is ETD -> pressure bandage -> elastic wrap. Inventory on the medic and patient is pooled deliberately,
 * independent of ACE shared-equipment preference, because either inventory is a valid source for this action.
 * Return: [plan, totalTime, complete], plan rows are [treatmentClass, itemClass, time].
 */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {[[], 0, false]};
_bodyPart = toLowerANSI _bodyPart;
private _partIndex = ["head","body","leftarm","rightarm","leftleg","rightleg"] find _bodyPart;
if (_partIndex < 0) exitWith {[[], 0, false]};

private _open = _patient getVariable ["ace_medical_openWounds", createHashMap];
private _source = _open getOrDefault [_bodyPart, []];
private _sim = _source apply {+_x};
if ((_sim findIf {(_x param [1, 0]) > 0.0001}) < 0) exitWith {[[], 0, true]};

private _priority = [
    ["EmergencyTraumaDressing", "ACM_EmergencyTraumaDressing"],
    ["PressureBandage", "ACM_PressureBandage"],
    ["ElasticWrap", "ACM_ElasticWrap"]
];
private _counts = createHashMap;
{
    _x params ["_treatment", "_item"];
    private _n = [_medic, _item] call ace_common_fnc_getCountOfItem;
    if (_patient != _medic) then {_n = _n + ([_patient, _item] call ace_common_fnc_getCountOfItem);};
    _counts set [_item, _n max 0];
} forEach _priority;

private _bandageRoot = configFile >> "ACE_Medical_Treatment" >> "Bandaging";
private _woundNames = missionNamespace getVariable ["ace_medical_damage_woundClassNamesComplex", []];
private _globalEff = missionNamespace getVariable ["ace_medical_treatment_bandageEffectiveness", 1];
private _rollover = missionNamespace getVariable ["ace_medical_treatment_bandageRollover", true];
private _advanced = missionNamespace getVariable ["ace_medical_treatment_advancedBandages", 0];
private _times = [BANDAGE_TIME_S, BANDAGE_TIME_M, BANDAGE_TIME_L];
private _plan = [];
private _total = 0;
private _guard = 0;

while {_guard < 128 && {(_sim findIf {(_x param [1, 0]) > 0.0001}) >= 0}} do {
    _guard = _guard + 1;
    private _pick = _priority findIf {(_counts getOrDefault [_x select 1, 0]) > 0};
    if (_pick < 0) exitWith {};
    (_priority select _pick) params ["_treatment", "_item"];
    private _cfg = _bandageRoot >> _treatment;
    private _baseEff = if (isNumber (_cfg >> "effectiveness")) then {getNumber (_cfg >> "effectiveness")} else {
        if (isNumber (_bandageRoot >> "effectiveness")) then {getNumber (_bandageRoot >> "effectiveness")} else {1}
    };

    private _remaining = _globalEff max 0.001;
    private _usedIdx = [];
    private _hits = [];
    private _madeProgress = false;
    while {_remaining > 0.0001} do {
        private _best = -1;
        private _bestScore = -1;
        private _bestEff = 0;
        private _bestImpact = 0;
        {
            if (_forEachIndex in _usedIdx) then {continue};
            _x params ["_classID", ["_amount", 0], ["_bleeding", 0]];
            if (_amount <= 0.0001) then {continue};
            private _className = _woundNames param [_classID, ""];
            private _eff = _baseEff;
            if (_className != "" && {isClass (_cfg >> _className)} && {isNumber (_cfg >> _className >> "effectiveness")}) then {
                _eff = getNumber (_cfg >> _className >> "effectiveness");
            };
            _eff = (_eff max 0) * _remaining;
            if (_eff <= 0.000001) then {continue};
            private _impact = _amount min _eff;
            private _score = _eff * _amount * (_bleeding max 0.0001);
            if (_score > _bestScore) then {
                _best = _forEachIndex; _bestScore = _score; _bestEff = _eff; _bestImpact = _impact;
            };
        } forEach _sim;
        if (_best < 0 || {_bestImpact <= 0}) exitWith {};
        _usedIdx pushBack _best;
        private _w = _sim select _best;
        _w set [1, ((_w select 1) - _bestImpact) max 0];
        _sim set [_best, _w];
        _hits pushBack [_w select 0, _bestEff, _bestImpact];
        _madeProgress = true;
        _remaining = (_remaining - (_bestImpact / _bestEff)) max 0;
        if (!_rollover) exitWith {};
    };

    if (!_madeProgress) then {
        // This item cannot treat the remaining wound class. Exhaust this tier for planning purposes and continue
        // to the next type instead of aborting the whole body-part plan.
        _counts set [_item, 0];
    } else {
        private _bandageTime = 0;
        {
            _x params ["_classID", "_eff", "_impact"];
            private _category = (_classID % 10) max 0 min 2;
            private _woundTime = _times select _category;
            if (_advanced != 0) then {
                _woundTime = _woundTime * linearConversion [0, _eff max 0.001, _impact, 0.666, 1, true];
            };
            _bandageTime = _bandageTime + _woundTime;
        } forEach _hits;
        // Match ACE getBandageTime semantics for each dressing, then sum every dressing in the bundle. This is what
        // makes a body part that needs three actual bandages take three bandages worth of time instead of one action's time.
        if ([_medic] call ace_medical_treatment_fnc_isMedic) then {_bandageTime = _bandageTime + BANDAGE_TIME_MOD_MEDIC;};
        if (_medic == _patient) then {_bandageTime = _bandageTime + BANDAGE_TIME_MOD_SELF;};
        if ((count _hits) > 1) then {_bandageTime = _bandageTime - (2 * count _hits);};
        _bandageTime = _bandageTime max 2.25;

        _plan pushBack [_treatment, _item, _bandageTime];
        _total = _total + _bandageTime;
        _counts set [_item, (_counts get _item) - 1];
    };
};

private _complete = (_sim findIf {(_x param [1, 0]) > 0.0001}) < 0;
[_plan, _total, _complete]
