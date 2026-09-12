// the hover feedback: light the slot up, and never darken it. the icon lifts and pops and its opacity goes from 85
// percent to 100, and the box tints a little lighter. on exit it returns to 85 percent, or stays at 100 if this
// tool is the selected one.
// note that arma dialog pictures cannot rotate, so the lift and scale is the dialog-native stand-in for a tilt.
// call it as [_btn, _enter] call ACME_fnc_thoraSlotHover.
params ["_btn", "_enter"];
if (isNull _btn) exitWith {};
private _ic = _btn getVariable ["thoraIcon", controlNull];
private _bg = _btn getVariable ["thoraBG", controlNull];
private _rect = _btn getVariable ["thoraIconRect", []];
private _tool = _btn getVariable ["thoraTool", ""];
private _held = uiNamespace getVariable ["ACME_Thora_Held", ""];
private _selected = (_held isEqualTo _tool) || {_tool == "tube" && {_held == "seal"}};

if (!isNull _ic && {count _rect == 4}) then {
    _rect params ["_ix", "_iy", "_iw", "_ih"];
    if (_selected) then {
        // the held tool: a static all-black silhouette left in its spot, with no lift, and the hover is ignored.
        _ic ctrlSetPosition [_ix, _iy, _iw, _ih];
        _ic ctrlSetTextColor [0, 0, 0, 1];
    } else {
        if (_enter) then {
            private _dx = _iw * 0.08;
            private _dy = _ih * 0.08;
            _ic ctrlSetPosition [_ix - _dx, _iy - _dy - (_ih * 0.06), _iw + (2 * _dx), _ih + (2 * _dy)];
            _ic ctrlSetTextColor [1, 1, 1, 1.0];
        } else {
            _ic ctrlSetPosition [_ix, _iy, _iw, _ih];
            _ic ctrlSetTextColor [1, 1, 1, 0.85];
        };
    };
    _ic ctrlCommit 0.05;
};
if (!isNull _bg) then {
    private _col = if (_selected) then {
        [0.20, 0.28, 0.18, 0.9]
    } else {
        if (_enter) then { [0.22, 0.22, 0.22, 0.85] } else { [0, 0, 0, 0.85] }
    };
    _bg ctrlSetBackgroundColor _col;
};
