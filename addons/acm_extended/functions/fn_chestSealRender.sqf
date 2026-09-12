// draw the current side: swap the body image, then show the found holes of this side, the correctly-placed seals,
// centerd on the wound and sized to cover it, and any wasted or misplaced seals, red-tinted, meaning placed but
// doing nothing.
// the controls are ctrlcreate'd lazily, and the sizes are aspect-true over the square body rect.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (isNull _display) exitWith {};

private _isFiniteNumber = {
    params ["_value"];
    ((typeName _value) isEqualTo "SCALAR") && {finite _value}
};

private _side = uiNamespace getVariable ["ACME_CS_Side", "front"];
private _bodyRect = uiNamespace getVariable ["ACME_CS_BodyRect", [0,0,0,0]];
if !(_bodyRect isEqualType [] && {count _bodyRect >= 4}) exitWith {};
_bodyRect params ["_bx", "_by", "_bw", "_bh"];
if !(([_bx] call _isFiniteNumber) && {[_by] call _isFiniteNumber} && {[_bw] call _isFiniteNumber} && {[_bh] call _isFiniteNumber} && {_bw > 0} && {_bh > 0}) exitWith {};

private _hw = uiNamespace getVariable ["ACME_CS_HoleW", 0.05];
private _hh = uiNamespace getVariable ["ACME_CS_HoleH", 0.05];
private _sw = uiNamespace getVariable ["ACME_CS_SealW", 0.03];
private _sh = uiNamespace getVariable ["ACME_CS_SealH", 0.05];
if !(([_hw] call _isFiniteNumber) && {_hw > 0}) then { _hw = _bw * 0.023; };
if !(([_hh] call _isFiniteNumber) && {_hh > 0}) then { _hh = _bh * 0.023; };
if !(([_sw] call _isFiniteNumber) && {_sw > 0}) then { _sw = _bw * 0.05; };
if !(([_sh] call _isFiniteNumber) && {_sh > 0}) then { _sh = _bh * 0.05; };

(_display displayCtrl 86401) ctrlSetText (if (_side == "front")
    then { "\x\acm\addons\gui\ui\body_background.paa" }
    else { "\acm_extended\ui\body_background_back.paa" });
(_display displayCtrl 86404) ctrlSetText (if (_side == "front")
    then { "\acm_extended\ui\cs_zone_front_ca.paa" }
    else { "\acm_extended\ui\cs_zone_back_ca.paa" });
[] call ACME_fnc_chestSealPrompt;

private _holes = uiNamespace getVariable ["ACME_CS_Holes", []];
{
    if (_x isEqualType [] && {count _x >= 8}) then {
        _x params ["_hSide", "_hx", "_hy", "_found", "_sealed", "_icon", "_cHole", "_cSeal"];
        private _onSide = (_hSide == _side);
        private _coordsValid = ([_hx] call _isFiniteNumber) && {[_hy] call _isFiniteNumber};

        if (_coordsValid) then {
            private _hpx = _bx + (_bw * _hx) - (_hw / 2);
            private _hpy = _by + (_bh * _hy) - (_hh / 2);

            // a found, not-yet-sealed hole shows the wound icon.
            if (_found && {!_sealed} && {_onSide} && {[_hpx] call _isFiniteNumber} && {[_hpy] call _isFiniteNumber}) then {
                if (isNull _cHole) then {
                    _cHole = _display ctrlCreate ["ACME_CS_Hole", -1];
                    _cHole ctrlEnable false;
                    _cHole ctrlSetText _icon;
                    (_holes select _forEachIndex) set [6, _cHole];
                };
                _cHole ctrlSetPosition [_hpx, _hpy, _hw, _hh];
                _cHole ctrlCommit 0;
                _cHole ctrlShow true;
            } else {
                if (!isNull _cHole) then { _cHole ctrlShow false; };
            };

            // sealed shows the seal centerd on the wound, covering it.
            private _sealX = _bx + (_bw * _hx) - (_sw / 2);
            private _sealY = _by + (_bh * _hy) - (_sh / 2);
            if (_sealed && {_onSide} && {[_sealX] call _isFiniteNumber} && {[_sealY] call _isFiniteNumber}) then {
                if (isNull _cSeal) then {
                    _cSeal = _display ctrlCreate ["ACME_CS_PlacedSeal", -1];
                    _cSeal ctrlEnable false;
                    (_holes select _forEachIndex) set [7, _cSeal];
                };
                _cSeal ctrlSetTextColor ([[1,1,1,0.95]] call ACME_fnc_cbColor);
                // the peel. a corner lifts across five frames, one frame per scroll notch, and comes back down
                // one frame at a time when the medic rolls the other way. it holds wherever they stop.
                private _burpIdx = uiNamespace getVariable ["ACME_CS_BurpIdx", -1];
                private _tex = "\x\acm\addons\breathing\ui\chestseal_ca.paa";
                if (_burpIdx == _forEachIndex) then {
                    // THE FRAME IS THE STATE. one scroll notch is one frame, held in ACME_CS_BurpFrame by
                    // fn_chestSealScroll, and this reads it. there is no elapsed time anywhere in it.
                    // it used to compute the frame from a timestamp, which could never have worked: this function
                    // is EVENT DRIVEN and never runs per frame, so a texture picked from elapsed time was written
                    // once and never advanced. a notch is an event and calls this directly, so the frames play.
                    private _fr = uiNamespace getVariable ["ACME_CS_BurpFrame", 0];
                    if (!(_fr isEqualType 0) || {!finite _fr}) then { _fr = 0; };
                    _fr = (round _fr) max 0 min 5;
                    if (_fr > 0) then {
                        // THE SIDE COMES FROM THE DIRECTION THE MEDIC ROLLED, not from where the wound sits.
                        // down peels from the right and up peels from the left. it names the art folder directly,
                        // so there is no mapping here to get backwards.
                        private _sd = uiNamespace getVariable ["ACME_CS_BurpSide", "right"];
                        if !(_sd in ["left", "right"]) then { _sd = "right"; };
                        _tex = format ["\acm_extended\ui\chest_seal\burp_%1\chest_seal_burp_%1_frame_0%2_ca.paa", _sd, _fr];
                    };
                };

                if (_burpIdx != _forEachIndex) then {
                    private _patient = uiNamespace getVariable ["ACME_CS_Patient", objNull];
                    private _peers = (missionNamespace getVariable ["ACME_CS_presence", createHashMap]) getOrDefault [netId _patient, createHashMap];
                    private _key = [_x] call ACME_fnc_chestSealKey;
                    private _latest = -1;
                    {
                        private _entry = _peers get _x;
                        private _peerBurp = _entry param [5, []];
                        private _at = _entry param [4, -1];
                        if (count _peerBurp >= 3 && {(_peerBurp select 0) isEqualTo _key} && {(_entry select 1) == _side}
                            && {diag_tickTime - _at <= (missionNamespace getVariable ["ACME_CS_presenceStale", 0.5])} && {_at > _latest}) then {
                            _latest = _at;
                            _tex = "\x\acm\addons\breathing\ui\chestseal_ca.paa";
                            private _fr = (round (_peerBurp select 1)) max 0 min 5;
                            private _corner = _peerBurp select 2;
                            if (_fr > 0 && {_corner in ["left", "right"]}) then {
                                _tex = format ["\acm_extended\ui\chest_seal\burp_%1\chest_seal_burp_%1_frame_0%2_ca.paa", _corner, _fr];
                            };
                        };
                    } forEach (keys _peers);
                };
                _cSeal ctrlSetText _tex;
                _cSeal ctrlSetPosition [_sealX, _sealY, _sw, _sh];
                _cSeal ctrlCommit 0;
                _cSeal ctrlShow true;
            } else {
                if (!isNull _cSeal) then { _cSeal ctrlShow false; };
            };
        } else {
            if (!isNull _cHole) then { _cHole ctrlShow false; };
            if (!isNull _cSeal) then { _cSeal ctrlShow false; };
        };
    };
} forEach _holes;
uiNamespace setVariable ["ACME_CS_Holes", _holes];

// wasted and misplaced seals, persisted, red-tinted and doing nothing.
private _patient = uiNamespace getVariable ["ACME_CS_Patient", objNull];
private _wasted = (uiNamespace getVariable ["ACME_CS_netSnapshot", []]) param [3, []];
private _wCtrls = uiNamespace getVariable ["ACME_CS_WastedCtrls", []];
{
    if (_x isEqualType [] && {count _x >= 3}) then {
        _x params ["_wSide", "_wx", "_wy"];
        private _c = _wCtrls param [_forEachIndex, controlNull];
        if (isNull _c) then {
            _c = _display ctrlCreate ["ACME_CS_PlacedSeal", -1];
            _c ctrlEnable false;
            _wCtrls set [_forEachIndex, _c];
        };
        if (_wSide == _side && {[_wx] call _isFiniteNumber} && {[_wy] call _isFiniteNumber}) then {
            private _sealX = _bx + (_bw * _wx) - (_sw / 2);
            private _sealY = _by + (_bh * _wy) - (_sh / 2);
            if (([_sealX] call _isFiniteNumber) && {[_sealY] call _isFiniteNumber}) then {
                _c ctrlSetTextColor (["danger2", 0.85] call ACME_fnc_a11yColor);
                _c ctrlSetPosition [_sealX, _sealY, _sw, _sh];
                _c ctrlCommit 0;
                _c ctrlShow true;
            } else {
                _c ctrlShow false;
            };
        } else {
            _c ctrlShow false;
        };
    };
} forEach _wasted;
// A reset or a shorter authoritative snapshot must also remove surplus old sprites.
for "_i" from (count _wasted) to ((count _wCtrls) - 1) do {
    private _old = _wCtrls select _i;
    if (!isNull _old) then { ctrlDelete _old; };
};
_wCtrls resize (count _wasted);
uiNamespace setVariable ["ACME_CS_WastedCtrls", _wCtrls];

// persisted NAR SPEAR placements use the supplied full-body overlays, so the device lands at the exact authored
// 5th-intercostal-space location and stays aligned on every resolution.
private _ncdCtrls = uiNamespace getVariable ["ACME_CS_NCDPlacedCtrls", []];
private _placedSides = (uiNamespace getVariable ["ACME_CS_netSnapshot", []]) param [4, []];
{
    if (!isNull _x) then {
        _x ctrlSetPosition [_bx, _by, _bw, _bh];
        _x ctrlCommit 0;
        private _patientSide = ["left", "right"] param [_forEachIndex, ""];
        _x ctrlSetTextColor ([[1,1,1,1]] call ACME_fnc_cbColor);
        _x ctrlShow (_side == "front" && {_patientSide in _placedSides});
    };
} forEach _ncdCtrls;
