if ([_this,"down"] call ACME_fnc_minigameInputMouse) exitWith {true};
// Shared display/control click router for the IV minigame.
// Left click holds for palpation, wiping and insertion.
// Right click on the applied band removes it; elsewhere it retracts the needle.
// With an empty hand, clicking a placed hub starts a pull.
// Slot buttons separately grab or return their tool on a single click.
// holding the band on the limb applies it at the snapped site.
// A needle click starts the stick; holding advances it and release ends the hold.
params ["_display", "_button", ["_evtX", -1], ["_evtY", -1]];
if (_display isEqualType controlNull) then {_display = ctrlParent _display;};
if !([] call ACME_fnc_ivUiValid) exitWith {false};
if (isNull _display || {_display != (uiNamespace getVariable ["ACME_IV_DLG", displayNull])}) exitWith {false};

if (_button in [1, 2]) exitWith {
    // Controls, their display and the CBA middle-button fallback can see the same
    // press. Consume it once so a band removal cannot also retract the needle.
    private _press = [diag_frameNo, _button];
    if ((_display getVariable ["ACME_IV_SecondaryPress", []]) isEqualTo _press) exitWith {true};
    _display setVariable ["ACME_IV_SecondaryPress", _press];

    private _hitBand = false;
    if (_button == 1 && {uiNamespace getVariable ["ACME_IV_BandOn", false]}
        && {!(uiNamespace getVariable ["ACME_IV_EJMode", false])}) then {
        private _body = uiNamespace getVariable ["ACME_IV_BodyRect", []];
        private _cursor = call ACME_fnc_ivMinigameCursor;
        private _band = uiNamespace getVariable ["ACME_IV_BandUV", []];
        if (count _body >= 4 && {count _cursor == 2} && {count _band >= 2}) then {
            _body params ["_x", "_y", "_w", "_h"];
            private _aspect = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
            if (_w > 0 && {_h > 0} && {_aspect > 0}) then {
                private _du = (((_cursor select 0) - _x) / _w) - (_band select 0);
                private _dv = ((((_cursor select 1) - _y) / _h) - (_band select 1)) / _aspect;
                _hitBand = sqrt ((_du * _du) + (_dv * _dv)) <= 0.05;
            };
        };
    };
    if (_hitBand) exitWith {
        [] call ACME_fnc_ivMinigameRemoveBand;
        true
    };
    // The established right/middle needle safety inputs remain available away
    // from the band. Space is still the keyboard equivalent.
    [] call ACME_fnc_ivMinigameRetract;
    true
};
if (_button != 0) exitWith { false };
uiNamespace setVariable ["ACME_IV_Dragging", true];

// an insertion is already under way. the catheter is in the arm, so this click is the medic taking hold of it
// again to push further, and it must not start a second stick.
private _insStage = uiNamespace getVariable ["ACME_IV_InsStage", ""];
if (_insStage in ["advance", "thread", "retract"]) exitWith { false };

private _finite = { params ["_v"]; (_v isEqualType 0) && {finite _v} };
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", []];
if (_rect isEqualTo []) exitWith { false };
_rect params ["_bx", "_by", "_bw", "_bh"];
private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];

private _ui = call ACME_fnc_ivMinigameCursor;
if (_ui isEqualTo []) exitWith { false };
_ui params ["_ux", "_uy"];
if !(([_ux] call _finite) && {[_uy] call _finite}) exitWith { false };

private _held = uiNamespace getVariable ["ACME_IV_Held", "none"];

// for a held needle, trust the last rendered hover position, because that is what the player is actually seeing.
// the MouseButtonDown coords and getMousePosition can disagree by a frame or a control space, which caused the
// base, inserted and hub images to split apart after the click.
private _lastNeedle = uiNamespace getVariable ["ACME_IV_LastNeedleState", []];
if (_held == "needle" && {_lastNeedle isEqualType []} && {count _lastNeedle >= 7}) then {
    _lastNeedle params ["_lu", "_lv", "_lFrame", "_lX", "_lY", "_lW", "_lH", ["_lt", 0]];
    if ((diag_tickTime - _lt) < 0.20) then {
        _ux = _bx + (_bw * _lu);
        _uy = _by + (_bh * _lv);
        uiNamespace setVariable ["ACME_IV_NeedleFrame", _lFrame];
        uiNamespace setVariable ["ACME_IV_StickTopLeft", [_lX, _lY]];
    };
};

private _fx = (_ux - _bx) / _bw;
private _fy = (_uy - _by) / _bh;

private _inRect = {
    params ["_px", "_py", "_r"];
    if !(_r isEqualType [] && {count _r >= 4}) exitWith { false };
    _r params ["_rx", "_ry", "_rw", "_rh"];
    (_px >= _rx) && {_px <= _rx + _rw} && {_py >= _ry} && {_py <= _ry + _rh}
};

// pull a placed iv out by taking hold of the hub.
// there is no remove button any more. take hold of the catheter and pull it, the same as you would on a body.
if (!(uiNamespace getVariable ["ACME_IV_EJMode", false]) || {true}) then {
    private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
    private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
    private _view = uiNamespace getVariable ["ACME_IV_View", ""];
    private _held0 = uiNamespace getVariable ["ACME_IV_Held", "none"];
    if (!isNull _patient && {_held0 == "none"} && {(uiNamespace getVariable ["ACME_IV_InsStage", ""]) == ""}) then {
        private _marks = _patient getVariable ["ACME_IV_Marks", []];
        private _bestI = -1;
        private _bestD = 1e9;
        {
            _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind"];
            if (_mbp == _bp && {_mview == _view} && {_mkind == "hub"}) then {
                private _du = _fx - _mu;
                private _dv = (_fy - _mv) * (1 / _af);
                private _d = sqrt ((_du * _du) + (_dv * _dv));
                if (_d < _bestD) then { _bestD = _d; _bestI = _forEachIndex; };
            };
        } forEach _marks;
        if (_bestI >= 0 && {_bestD <= (missionNamespace getVariable ["ACME_iv_pullGrabRadius", 0.05])}) exitWith {
            (_marks select _bestI) params ["", "", "", "", "", "", ["_pframe", ""]];
            uiNamespace setVariable ["ACME_IV_PullIdx", _bestI];
            uiNamespace setVariable ["ACME_IV_PullSuffix", _pframe];
            uiNamespace setVariable ["ACME_IV_PullAngle", (_marks select _bestI) param [13,0]];
            uiNamespace setVariable ["ACME_IV_PullProg", 0];
            uiNamespace setVariable ["ACME_IV_PullBroke", false];
            uiNamespace setVariable ["ACME_IV_PullPin", getMousePosition];
            // the mark sprite for this hub becomes the thing being pulled, so the render leaves it alone.
            private _mc = controlNull;
            {
                if ((_x select 0) == _bestI) exitWith { _mc = _x select 1; };
            } forEach (uiNamespace getVariable ["ACME_IV_HubCtrls", []]);
            uiNamespace setVariable ["ACME_IV_PullCtrl", _mc];
            if (!isNull _mc) then {
                (ctrlPosition _mc) params ["_p0x", "_p0y"];
                uiNamespace setVariable ["ACME_IV_PullBase", [_p0x, _p0y]];
            };
            false
        };
    };
};

// slot grabs are handled by the onButtonClick of each slot button, as a single click that toggles to return. we
// intentionally do not hit-test slots here, because doing so double-fired the grab, once down here and once on
// the click of the button on release, which is why an item only stuck if you dragged out of the box.

private _onBody = (_ux >= _bx) && {_ux <= _bx + _bw} && {_uy >= _by} && {_uy <= _by + _bh};

switch (_held) do {
    // apply the band at the snapped site.
    case "band": {
        if (!_onBody) exitWith {};
        private _snap = uiNamespace getVariable ["ACME_IV_SnapActive", []];
        if (_snap isEqualTo []) exitWith {};
        _snap params ["_sName", "_sbU", "_sbV", "_svU", "_svV", "_slbl", "_sBandTex"];
        uiNamespace setVariable ["ACME_IV_Site", _sName];
        uiNamespace setVariable ["ACME_IV_BandUV", [_sbU, _sbV]];
        uiNamespace setVariable ["ACME_IV_VeinUV", [_svU, _svV]];
// the candidate veins at this site. outside the antecubital fossa this is the single strip it always was.
uiNamespace setVariable ["ACME_IV_VeinSet",
    [(uiNamespace getVariable ["ACME_IV_Patient", objNull]),
     (uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"]),
     _sName, _svU, _svV] call ACME_fnc_ivVeinSet];
        uiNamespace setVariable ["ACME_IV_Label", _slbl];
        (_display displayCtrl 86504) ctrlSetText _slbl;
        uiNamespace setVariable ["ACME_IV_BandOn", true];
        uiNamespace setVariable ["ACME_IV_Held", "none"];
        uiNamespace setVariable ["ACME_IV_Cleaned", false];
        uiNamespace setVariable ["ACME_IV_BandTex", _sBandTex];
        private _bC = _display displayCtrl 86502;
        _bC ctrlSetText _sBandTex;
        _bC ctrlSetPosition [_bx, _by, _bw, _bh];
        _bC ctrlCommit 0;
        _bC ctrlShow true;
        (_display displayCtrl 86505) ctrlShow false;
        // seed the difficulty, at the default gauge, so the palpation feel reflects the patency.
        private _patient0  = uiNamespace getVariable ["ACME_IV_Patient", objNull];
        private _bodyPart0 = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
        private _diff0 = [_patient0, _bodyPart0, 16, (uiNamespace getVariable ["ACME_IV_Site", 1])] call ACME_fnc_ivSiteDifficulty;
        _diff0 params ["_pat0", "_feel0", "_hit0", "_hot0"];
        uiNamespace setVariable ["ACME_IV_Patency", _pat0];
        uiNamespace setVariable ["ACME_IV_FeelRadius", _feel0];
        uiNamespace setVariable ["ACME_IV_HitRadius", _hit0];
        uiNamespace setVariable ["ACME_IV_MaxHot", _hot0];
        [] call ACME_fnc_ivMinigameRefreshBandSlot;
        [true] call ACME_fnc_ivMinigameBandFlag;  // a band on the limb stops a line running through it.
        [] call ACME_fnc_ivMinigameSaveState;
    };

    // holding a needle: the click is the stick. it only counts if it lands on the limb, and off the limb it does
    // nothing and the needle stays in hand. on the limb, a hit seats the catheter and a non-hit is a wasted miss.
    case "needle": {
        private _onLimb = (_fx >= 0) && {_fx <= 1} && {_fy >= 0} && {_fy <= 1};
        if (_onLimb) then {
            // aim from the point of the needle, not from the pointer.
            // the needle lags the cursor and trembles, so the two are not in the same place. the tip is what
            // touches the skin, so the tip is what the vein is measured against. without this the medic could hit
            // a vein the steel was not over, and a tremor would cost them nothing.
            private _tipUV = uiNamespace getVariable ["ACME_IV_NeedleTipUV", []];
            if (_tipUV isEqualType [] && {count _tipUV >= 3} && {(diag_tickTime - (_tipUV select 2)) < 0.25}) then {
                _fx = _tipUV select 0;
                _fy = _tipUV select 1;
            };
            private _isEJc = uiNamespace getVariable ["ACME_IV_EJMode", false];

            // NO GATE STOPS A STICK. The medic decides when and where to put a catheter.
            // r-27 to r-31 required a band on the limb and refused an occupied location. Both are removed.
            // The band is a separate action. The medic applies it and removes it at any time.

            // Find the point of entry of the needle. The site comes from the puncture.
            // A stick in the fossa is a fossa IV. The site of the band does not change this.
            private _stickSite = "";
            if (!_isEJc) then {
                _stickSite = [_fx, _fy] call ACME_fnc_ivSiteAtPoint;
            };

            // the site diagnostic is removed. it defaulted to on and it wrote to the RPT on every stick.
            // ACME_iv_siteDebug is no longer read by anything in this file.

            private _hit = uiNamespace getVariable ["ACME_IV_HitRadius", 0.004];
            // Judge the puncture site, not a cached band-site margin. This also fixes the
            // 14g wrist tolerance when the band or another observer changes the selected site.
            if (!_isEJc && {_stickSite in ["upper", "middle", "lower"]}) then {
                private _punctureDifficulty = [uiNamespace getVariable ["ACME_IV_Patient", objNull],
                    uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"],
                    uiNamespace getVariable ["ACME_IV_Gauge", 16], _stickSite] call ACME_fnc_ivSiteDifficulty;
                _hit = _punctureDifficulty select 2;
            };
            private _distV = [_fx, _fy] call ACME_fnc_ivVeinDist;
            if (_distV > _hit) then {
                // the needle goes into the skin exactly as it would on a good stick, and the catheter can be
                // pushed all the way in. the medic finds out at the end, when the line will not run.
                // the accuracy is recorded as the worst case, so the blown-vein check cannot read a stale value
                // from an earlier stick.
                uiNamespace setVariable ["ACME_IV_StickAcc", 1];
                [_fx, _fy, false, _stickSite] call ACME_fnc_ivMinigameInsertStart;
            } else {
                // how good was the stick, as a fraction of the target. 0 is dead on the vein and 1 is the very
                // edge of what counted as a hit.
                // it is recorded because landing the needle is not the only question. a wide cannula that just
                // clipped the wall of the vein is not the same as one that went straight down the middle of it,
                // and fn_ivminigamesticksuccess uses this to decide whether the vein blew.
                uiNamespace setVariable ["ACME_IV_StickAcc", (if (_hit > 0) then { (_distV / _hit) min 1 } else { 0 })];
                (uiNamespace getVariable ["ACME_IV_VeinUV", [0.5, 0.5]]) params ["_vu", "_vv"];
                private _half = uiNamespace getVariable ["ACME_IV_StripHalf", 0.045];
                // store the actual click point rather than the snapped vein centerline. success is still gated by the distance to
                // the vein, and the visible seated catheter and hub must land exactly where the medic clicked. this keeps limb
                // IVs and ej placement pixel-accurate with the cursor.
                private _stickU = _fx;
                private _stickV = _fy;
                private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
                private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
                private _view = uiNamespace getVariable ["ACME_IV_View", ""];
                private _blocked = false; private _reason = "";
                if (!isNull _patient) then {
                    {
                        _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""], ["_mframe", ""], ["_mgauge", 0], ["_mmiss", -1], ["_mscale", 1], ["_msite", ""]];
                        if (_mbp == _bp && {_mview == _view}) then {
                            private _du = _stickU - _mu; private _dv = (_stickV - _mv) * (1 / _af);
                            if (sqrt ((_du * _du) + (_dv * _dv)) <= 0.03) then { _blocked = true; _reason = "used"; };
                            private _sameDrainageTrack = (!_isEJc) || {(toLowerANSI _msite) == (toLowerANSI (uiNamespace getVariable ["ACME_IV_EJAnatomicalSide", ""]))};
                            if (_sameDrainageTrack && {_mkind == "removed"} && {_stickV >= _mv - 0.012}) then { _blocked = true; _reason = "above"; };
                        };
                    } forEach (_patient getVariable ["ACME_IV_Marks", []]);
                };
                if (_blocked) then {
                    (_display displayCtrl 86503) ctrlSetText (if (_reason == "above") then { "" } else { "That site is already used." });
                } else {
                    [_stickU, _stickV, true, _stickSite] call ACME_fnc_ivMinigameInsertStart;
                };
            };
        };
    };

    // holding the tubing: click the seated hub to connect it.
    case "line": {
        if (!_onBody) exitWith {};
        [_fx, _fy] call ACME_fnc_ivMinigameLineConnect;
    };

    // Empty hand and pad holds continue into palpation/wiping in the tick.
    default {};
};
false
