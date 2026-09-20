/* Prep Infusion live physical-vial clamp + throttled stock refresh.
 *
 * ACM's native syringe loop limits travel from the medication config volume. Prep Infusion additionally binds the
 * selected medication to one physical vial at a time. This function runs locally every frame so that physical vial
 * limit is authoritative while the plunger is grabbed, exactly like the Narc Box compound draw. Inventory is still
 * consumed only by Inject Into Bag; this loop only owns local UI state.
 */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display || {isNil "ACME_infusion_pendingContext"}) exitWith {};
private _list = _display displayCtrl 84006;
if (isNull _list) exitWith {};
_list ctrlShow false;

private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _drawn = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
if (!finite _drawn) then {_drawn = 0;};
_drawn = _drawn max 0;
private _allowed = missionNamespace getVariable ["ACME_infusion_allowedMedications", []];

if (_med != "" && {_med in _allowed}) then {
    private _size = (missionNamespace getVariable ["ACM_circulation_SyringeDraw_Size", 10]) max 0.1;
    private _sessionMax = (["limit", _med, _drawn, _display] call ACME_fnc_vialSession) max 0;
    private _holder = [ACE_player] call ACME_fnc_vialHolder;
    private _stockMax = if (isNull _holder) then {0} else {[_holder, _med] call ACME_fnc_infusionVialVolume};
    if (!finite _stockMax) then {_stockMax = 0;};
    private _hardMax = (_size min _sessionMax min (_stockMax max 0)) max 0;

    // Keep ACM's own loop informed too, but do not depend on scheduling order. The live branch below is the final
    // local writer after ACM and physically clamps the hit control, visible plunger, cursor and DrawnAmount together.
    missionNamespace setVariable ["ACM_circulation_SyringeDraw_MaxDose", _hardMax];

    private _moving = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false];
    if (_moving) then {
        private _top = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitTop", -1];
        private _bottom = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitBottom", -1];
        private _plunger = _display displayCtrl 84009;

        if (_top >= 0 && {_bottom >= 0} && {!isNull _plunger}) then {
            private _visualIdc = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerVisual", -1];
            private _visual = if (_visualIdc >= 0) then {_display displayCtrl _visualIdc} else {controlNull};
            private _adjust = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerAdjustment", 0];

            (ctrlPosition _plunger) params ["_px", "", "_pw", "_ph"];
            private _mouseOffset = _ph / 2;
            private _maxY = linearConversion [0, _size, _hardMax, _top, _bottom, true];
            private _topMouse = _top + _mouseOffset;
            private _maxMouse = _maxY + _mouseOffset;
            getMousePosition params ["_mouseX", "_mouseY"];

            // Press against the end of the selected vial instead of allowing the cursor/plunger to travel beyond it.
            // Moving upward remains immediate, so medication can be returned to that same vial normally.
            private _mouseYClamped = _maxMouse min _mouseY max _topMouse;
            setMousePosition [_px + (_pw / 2), _mouseYClamped];
            private _newY = (_mouseYClamped - _mouseOffset) min _maxY max _top;
            private _amount = linearConversion [_top, _bottom, _newY, 0, _size, true];
            _amount = (_amount max 0) min _hardMax;

            // Resolve the same sub-pixel endpoint rounding already handled by the Narc Box. This lets the vial read
            // exactly 0.00 mL at the hard stop and lets the syringe return exactly to empty at the top.
            if ((_newY - _top) <= (2 * pixelH) && {_amount <= 0.015}) then {
                _amount = 0;
                _newY = _top;
            };
            if ((_maxY - _newY) <= (2 * pixelH) && {(_hardMax - _amount) <= 0.015}) then {
                _amount = _hardMax;
                _newY = _maxY;
            };

            _plunger ctrlSetPosition [_px, _newY, _pw, _ph];
            _plunger ctrlCommit 0;
            if (!isNull _visual) then {
                (ctrlPosition _visual) params ["_vx", "", "_vw", "_vh"];
                _visual ctrlSetPosition [_vx, _newY - _adjust, _vw, _vh];
                _visual ctrlCommit 0;
            };
            missionNamespace setVariable ["ACM_circulation_SyringeDraw_DrawnAmount", _amount];
            _drawn = _amount;
        };
    } else {
        // If stock changes while the plunger is released, repair all syringe state together instead of changing the
        // amount alone and leaving the visible plunger/hit control at the old position.
        if (_drawn > _hardMax + 0.0001) then {
            [_hardMax, _display, false] call ACME_fnc_syringeDrawSetAmount;
            _drawn = _hardMax;
        };
    };
};

private _busy = (missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "";
private _movingNow = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false];
(_display displayCtrl 84003) ctrlEnable (!_busy && {!_movingNow} && {_drawn > 0} && {_med in _allowed});

// The clamp must run every frame, but rebuilding stock rows/tally every frame is unnecessary. Keep that work at
// 10 Hz so this remains a cheap local UI loop with no added multiplayer/network traffic.
private _now = diag_tickTime;
private _nextRefresh = _display getVariable ["ACME_infusionNextStockRefresh", 0];
if (_now >= _nextRefresh) then {
    _display setVariable ["ACME_infusionNextStockRefresh", _now + 0.10];
    [_display] call ACME_fnc_skMedicationSync;
    _list ctrlShow false;
    [_display] call ACME_fnc_skMedicationStockRefresh;
    [] call ACME_fnc_infusionRefreshTally;
};
