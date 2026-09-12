private _scroll = 0;
if (_this isEqualType []) then {
    _scroll = _this param [1, 0];
} else {
    _scroll = _this;
};
if (_scroll == 0) exitWith {false};
if (uiNamespace getVariable ["ACME_RollerClamp_Dragging", false]) exitWith {false};

// one step per frame, regardless of how many controls relay the same event.
private _frame = diag_frameno;
if ((uiNamespace getVariable ["ACME_RollerClamp_ScrollFrame", -1]) == _frame) exitWith {true};
uiNamespace setVariable ["ACME_RollerClamp_ScrollFrame", _frame];

private _position = uiNamespace getVariable ["ACME_RollerClamp_Position", 1];

private _step = missionNamespace getVariable ["ACME_infusion_clampScrollStep", 0.10];
// the base direction is +1, so a scroll up opens, matching the flipped up-is-open wheel. the CBA checkbox inverts
// it.
private _direction = [1, -1] select (missionNamespace getVariable ["ACME_infusion_clampScrollInvert", false]);
private _delta = [_step, -_step] select (_scroll <= 0);
private _next = (_position + (_delta * _direction)) max 0 min 1;

// move the wheel immediately. the data commit follows if a bag context exists.
uiNamespace setVariable ["ACME_RollerClamp_Position", _next];
[_next] call ACME_fnc_placeClampWheel;
[_next] call ACME_fnc_playClampSfx;
uiNamespace setVariable ["ACME_RollerClamp_Flash", [format ["Clamp %1%2 open", round (_next * 100), "%"], CBA_missionTime + 0.85]];

[_next, true] call ACME_fnc_setClampPosition;
call ACME_fnc_updateClampDialog;
true
