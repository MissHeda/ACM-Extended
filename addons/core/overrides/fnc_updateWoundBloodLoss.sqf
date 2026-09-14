#include "\x\ACM\addons\core\script_component.hpp"
/*
 * Author: Glowbal
 * Update total wound bleeding based on open wounds and tourniquets
 * Wound bleeding = percentage of cardiac output lost
 *
 * Arguments:
 * 0: The Unit <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player] call ace_medical_status_fnc_updateWoundBloodLoss
 *
 * Public: No
 */

params ["_unit"];
private _acmeBinding = "NA3:updateWoundBloodLoss";

private _tourniquets = GET_TOURNIQUETS(_unit);
private _bodyPartBleeding = [0,0,0,0,0,0];
{
    private _partIndex = ALL_BODY_PARTS find _x;
    if (_tourniquets select _partIndex == 0 && {!([_unit, _partIndex] call ACME_fnc_aajtOccludes)}) then {
        {
            _x params ["", "_amountOf", "_bleeding"];
            _bodyPartBleeding set [_partIndex, (_bodyPartBleeding select _partIndex) + (_amountOf * _bleeding)];
        } forEach _y;
    };
} forEach GET_OPEN_WOUNDS(_unit);

// B107: a dressing controls hemorrhage progressively while it is physically being applied.  The start event
// records the bleed reduction that the completed bandage is expected to produce.  Apply a quadratic ease-in so
// control is modest early in the timer and accelerates as the provider gets closer to securing the dressing.
// No wound amount is mutated here.  On interruption the record disappears and the original bleeding returns;
// on success ACE's normal bandage callback performs the permanent wound change.
private _bandageProgress = _unit getVariable [QEGVAR(damage,BandageProgress), createHashMap];
if (_bandageProgress isEqualType createHashMap && {count _bandageProgress > 0}) then {
    private _expiredBandages = [];
    {
        _y params ["_part", "_finalReduction", "_startedAt", "_duration", ["_bandageClass", ""]];
        private _age = CBA_missionTime - _startedAt;
        if (_age > (_duration + 2)) then {
            _expiredBandages pushBack _x;
        } else {
            private _partIndex = ALL_BODY_PARTS find _part;
            if (_partIndex >= 0 && {_finalReduction > 0}) then {
                private _progress = (_age / (_duration max 0.01)) max 0 min 1;
                private _control = _progress * _progress;
                private _current = _bodyPartBleeding select _partIndex;
                _bodyPartBleeding set [_partIndex, (_current - (_finalReduction * _control)) max 0];
            };
        };
    } forEach _bandageProgress;

    if (_expiredBandages isNotEqualTo []) then {
        { _bandageProgress deleteAt _x; } forEach _expiredBandages;
        _unit setVariable [QEGVAR(damage,BandageProgress), _bandageProgress, true];
    };
};

// B102: direct pressure gets a modest immediate effect on ordinary external limb bleeding. This is deliberately
// limb-only. Head and torso pressure keep their existing behavior unchanged. The clinical marker is cleared while
// movement or an incompatible maneuver yields pressure, so this multiplier only exists while pressure is actually
// being maintained.
private _dpLimbMult = missionNamespace getVariable ["ACME_DP_limbBleedMult", 0.72];
{
    private _partIndex = _x;
    private _part = ALL_BODY_PARTS select _partIndex;
    private _provider = _unit getVariable [format ["ACME_DP_press_%1", _part], objNull];
    if (!isNull _provider
        && {alive _provider}
        && {_provider getVariable ["ACME_DP_Active", false]}
        && {!(_provider getVariable ["ACME_DP_Paused", false])}) then {
        _bodyPartBleeding set [_partIndex, (_bodyPartBleeding select _partIndex) * _dpLimbMult];
    };
} forEach [2,3,4,5];

// Internal bleeding
private _bodyPartInternalBleeding = [0,0,0,0,0,0];
{
    private _partIndex = ALL_BODY_PARTS find _x;
    if (_tourniquets select _partIndex == 0 && {!([_unit, _partIndex] call ACME_fnc_aajtOccludes)}) then {
        {
            _x params ["", "_woundCount", "_bleedRate"];

            _bodyPartInternalBleeding set [_partIndex, (_bodyPartInternalBleeding select _partIndex) + (_woundCount * _bleedRate)];
        } forEach _y;
    };
} forEach GET_INTERNAL_WOUNDS(_unit);

/*if (GVAR(Hardcore_InternalBleeding)) then {
    [_unit] call EFUNC(damage,handleHardcoreInternalBleeding);
};*/

if (_bodyPartInternalBleeding isEqualTo [0,0,0,0,0,0]) then {
    _unit setVariable [VAR_INTERNAL_BLEEDING, 0, true];
} else {
    _bodyPartInternalBleeding params ["_headB", "_bodyB", "_leftArmB", "_rightArmB", "_leftLegB", "_rightLegB"];

    private _bodyBleedingRate = ((_headB min 0.9) + (_bodyB min 1.0)) min 1.0;
    private _limbBleedingRate = ((_leftArmB min 0.3) + (_rightArmB min 0.3) + (_leftLegB min 0.5) + (_rightLegB min 0.5)) min 1.0;

    _limbBleedingRate = _limbBleedingRate * (1 - _bodyBleedingRate);

    _unit setVariable [VAR_INTERNAL_BLEEDING, (_bodyBleedingRate + _limbBleedingRate), true];
    
    if !(_unit getVariable [QGVAR(IBCoagulation_Active), false]) then {
        [QEGVAR(damage,handleIBCoagulationPFH), [_unit], _unit] call CBA_fnc_targetEvent;
    };
};

if (_bodyPartBleeding isEqualTo [0,0,0,0,0,0]) then {
    TRACE_1("updateWoundBloodLoss-none",_unit);
    _unit setVariable [VAR_WOUND_BLEEDING, 0, true];
} else {
    _bodyPartBleeding params ["_headB", "_bodyB", "_leftArmB", "_rightArmB", "_leftLegB", "_rightLegB"];

    private _bodyBleedingRate = 0; 
    private _limbBleedingRate = 0;
    
    if (GET_INTERNAL_BLEEDING(_unit) > 0.3) then { // Severe internal bleeding slows external bleeding
        _bodyPartInternalBleeding params ["_headIB", "_bodyIB", "_leftArmIB", "_rightArmIB", "_leftLegIB", "_rightLegIB"];

        _bodyBleedingRate = ((((_headB - _headIB) max 0) min 0.9) + (((_bodyB - _bodyIB) max 0) min 1.0)) min 1.0;
        _limbBleedingRate = ((((_leftArmB - _leftArmIB) max 0) min 0.3) + (((_rightArmB - _rightArmIB) max 0) min 0.3) + (((_leftLegB - _leftLegIB) max 0) min 0.5) + (((_rightLegB - _rightLegIB) max 0) min 0.5)) min 1.0;
    } else {
        _bodyBleedingRate = ((_headB min 0.9) + (_bodyB min 1.0)) min 1.0;
        _limbBleedingRate = ((_leftArmB min 0.3) + (_rightArmB min 0.3) + (_leftLegB min 0.5) + (_rightLegB min 0.5)) min 1.0;
    };

    // limb bleeding is scaled down based on the amount of body bleeding
    _limbBleedingRate = _limbBleedingRate * (1 - _bodyBleedingRate);

    TRACE_3("updateWoundBloodLoss-bleeding",_unit,_bodyBleedingRate,_limbBleedingRate);
    _unit setVariable [VAR_WOUND_BLEEDING, _bodyBleedingRate + _limbBleedingRate, true];

    if (EGVAR(circulation,coagulationClotting) && (EGVAR(circulation,coagulationClottingAffectAI) || (!(EGVAR(circulation,coagulationClottingAffectAI)) && isPlayer _unit))) then {
        if !(_unit getVariable [QGVAR(Coagulation_Active), false]) then {
            [QEGVAR(damage,handleCoagulationPFH), [_unit], _unit] call CBA_fnc_targetEvent;
        };
    };
};
