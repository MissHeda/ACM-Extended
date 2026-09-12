// the index of the sealed wound under the cursor on the current view, or -1 when there is none.
// call it as [] call ACME_fnc_chestSealSealAt.
//
// this is one copy of a search that had been written out three times, in fn_chestSealMouseDown for the right
// click peel, in fn_chestSealScroll for the burp, and about to be a third time for the hover check. all three
// need the SAME reach and the SAME test, or a seal you can peel is one you cannot burp, and a seal the wheel
// grabs is one the hover check thinks you are not on.
// the radius is ACME_CS_ApplyR, written by fn_chestSealInit as a fraction of the body height, in the same ui
// space as the distance below. it is not a body fraction and the two are not interchangeable.
private _isFiniteNumber = {
    params ["_value"];
    ((typeName _value) isEqualTo "SCALAR") && {finite _value}
};

private _bodyRect = uiNamespace getVariable ["ACME_CS_BodyRect", [0,0,0,0]];
if !(_bodyRect isEqualType [] && {count _bodyRect >= 4}) exitWith {-1};
_bodyRect params ["_bx", "_by", "_bw", "_bh"];
if !(([_bx] call _isFiniteNumber) && {[_by] call _isFiniteNumber} && {[_bw] call _isFiniteNumber} && {[_bh] call _isFiniteNumber} && {_bw > 0} && {_bh > 0}) exitWith {-1};

private _mouse = [_bodyRect, true] call ACME_fnc_chestSealMouseCoords;
if !(_mouse isEqualType [] && {count _mouse >= 2}) exitWith {-1};
_mouse params ["_mx", "_my"];
if !(([_mx] call _isFiniteNumber) && {[_my] call _isFiniteNumber}) exitWith {-1};

private _side = uiNamespace getVariable ["ACME_CS_Side", "front"];
private _af = uiNamespace getVariable ["ACME_CS_AspectFix", 0.5625];
if !(([_af] call _isFiniteNumber) && {_af > 0.05} && {_af < 4}) then {_af = 0.5625;};

private _applyR = uiNamespace getVariable ["ACME_CS_ApplyR", (_bh * 0.062)];
if !(([_applyR] call _isFiniteNumber) && {_applyR > 0}) then {_applyR = _bh * 0.062;};

private _holes = uiNamespace getVariable ["ACME_CS_Holes", []];
if !(_holes isEqualType []) exitWith {-1};

private _onSeal = -1;
private _onSealD = _applyR;
{
    if (_x isEqualType [] && {count _x >= 5}) then {
        _x params ["_sSide", "_sx", "_sy", "_sFound", "_sSealed"];
        if (_sFound && {_sSealed} && {_sSide == _side} && {[_sx] call _isFiniteNumber} && {[_sy] call _isFiniteNumber}) then {
            private _sdx = (_mx - (_bx + _bw * _sx)) / (_af max 0.05);
            private _sdy = _my - (_by + _bh * _sy);
            private _sd = sqrt (((_sdx * _sdx) + (_sdy * _sdy)) max 0);
            if (([_sd] call _isFiniteNumber) && {_sd < _onSealD}) then { _onSeal = _forEachIndex; _onSealD = _sd; };
        };
    };
} forEach _holes;

_onSeal
