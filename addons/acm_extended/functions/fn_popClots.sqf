// reopen bandaged, or clotted, wounds on a patient. a fresh clot tears loose and that wound bleeds again.
// it mirrors the own bandage-reopening surgery of ACE: move a fraction of the amount of each bandaged wound back
// onto the matching open wound, index 1, then recompute the blood loss.
// it runs where the unit is local, because the cold-chain tick targetevents this to the owner of the patient, so the
// medical sim picks the new bleeding up authoritatively.
params ["_unit", ["_fraction", 0.5]];
if (isNull _unit || {!alive _unit}) exitWith {};

private _open     = _unit getVariable ["ace_medical_openWounds", createHashMap];
private _bandaged = _unit getVariable ["ace_medical_bandagedWounds", createHashMap];
private _popped = 0;

{
    private _part    = _x;
    private _bWounds = _bandaged get _part;
    private _oWounds = _open getOrDefault [_part, []];
    private _touched = false;
    {
        _x params ["_bid", "_bamt"];
        if (_bamt > 0.01) then {
            private _move = _bamt * _fraction;
            // add the freed amount back onto the matching open wound, by class, or rebuild one if it is gone.
            private _oi = _oWounds findIf { (_x select 0) == _bid };
            if (_oi > -1) then {
                private _ow = _oWounds select _oi;
                _ow set [1, (_ow select 1) + _move];
            } else {
                private _new = +_x;
                _new set [1, _move];
                _oWounds pushBack _new;
            };
            _x set [1, _bamt - _move];
            _popped = _popped + 1;
            _touched = true;
        };
    } forEach _bWounds;
    if (_touched) then { _open set [_part, _oWounds]; };
} forEach (keys _bandaged);

if (_popped > 0) then {
    [_unit, [["openWounds", _open, true]]] call ACM_core_fnc_setAceMedicalState;
    [_unit, [["bandagedWounds", _bandaged, true]]] call ACM_core_fnc_setAceMedicalState;
    [_unit] call ace_medical_status_fnc_updateWoundBloodLoss;
    if (_unit isEqualTo ACE_player) then {
        ["A clot tore loose - bleeding has restarted.", 2] call ace_common_fnc_displayTextStructured;
    };
};
_popped
