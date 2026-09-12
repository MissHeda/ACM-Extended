// shake the whole dialog: every control, every frame, as one object.
// on the model, and why the previous one was broken at the root. the old version captured the resting position of
// each control once and then forced it to base plus offset forever. that works fine for the panel chrome, which
// nothing else ever touches. it is fatal for any control that some other code positions: the wound holes, the
// incision, the chest tube, the prep dots and the iv marks. their render functions place them on the body, and
// the shake then ran on the next frame and dragged them straight back to whatever position they happened to be
// sitting at when they were first captured, usually their pre-created init spot, off in a corner of the panel.
// that is why the chlorhexidine disappeared and why the thoracostomy wound was drawn nowhere near the chest. one
// bug, two symptoms. patching one of them by redrawing prep every frame was treating the symptom, and it would
// have left every other mark in the addon quietly broken.
// the fix is that the shake watches for a control being moved by someone else. each frame we compare where a
// control actually is against where we last put it. if they differ, something else moved it deliberately, so we
// adopt that as its new resting place, backing out the offset that was applied when it was moved, because the
// render functions position from the already-shaken body rect. then we shake it from there.
// this is self-correcting and needs no list of exceptions. any render function anywhere in the addon can move any
// control at any time, and the shake simply follows it. nothing has to know about anything else.
// call it as [_display, _storeKey] call ACME_fnc_uiShakeApply, which returns [_dx, _dy].
params ["_display", "_storeKey"];
if (isNull _display) exitWith {[0, 0]};

// the darkness is screen-space and never shakes. the cabin moves, your eyes do not, and the torch is in your
// hand.
private _excl = [];  // B10 does not create a private NV overlay.
{ _excl append (uiNamespace getVariable [_x, []]); } forEach ["ACME_IV_Shade", "ACME_CS_Shade", "ACME_Thora_Shade"];
{ _excl pushBack _x; } forEach (uiNamespace getVariable ["ACME_light_ctrls", []]);

private _known   = uiNamespace getVariable [_storeKey, []];  // [[ctrl, restingpos, lastposweset], ...].
private _lastOff = uiNamespace getVariable [_storeKey + "_off", [0, 0]];
_lastOff params [["_lox", 0], ["_loy", 0]];

// pick up controls created since we last looked, such as marks, holes and bruises. they are born from the shaken
// body rect, so their birth position already contains an offset, and it is backed out to get their true rest.
private _all = (allControls _display) select {
    !(_x in _excl) && {!(_x getVariable ["ACME_NV_OverlayControl", false])}
    && {!(_x getVariable ["ACME_UI_NoShake", false])}
};
// Deleted/replaced controls can leave the total count unchanged.
_known = _known select {!isNull (_x select 0) && {(_x select 0) in _all}};
if ((count _known) != (count _all)) then {
    _known = _known select { !isNull (_x select 0) && {!((_x select 0) in _excl)} };
    private _knownCtrls = _known apply { _x select 0 };
    {
        private _c = _x;
        if ((_knownCtrls find _c) < 0) then {
            private _p = ctrlPosition _c;
            if ((_p isEqualType []) && {(count _p) >= 4}) then {
                _p params ["_cx", "_cy", "_cw", "_ch"];
                if ((_cx isEqualType 0) && {finite _cx} && {finite _cy}) then {
                    _known pushBack [_c, [_cx - _lox, _cy - _loy, _cw, _ch], _p];
                };
            };
        };
    } forEach _all;
    uiNamespace setVariable [_storeKey, _known];
};

([] call ACME_fnc_motionShake) params [["_dx", 0], ["_dy", 0]];

// one bad number here does not stay here. it goes into ctrlSetPosition and corrupts every control in the
// dialog.
if (!(_dx isEqualType 0) || {!(finite _dx)}) then { _dx = 0; };
if (!(_dy isEqualType 0) || {!(finite _dy)}) then { _dy = 0; };

{
    _x params ["_c", "_base", "_mine"];
    if (!isNull _c) then {
        private _now = ctrlPosition _c;
        if ((_now isEqualType []) && {(count _now) >= 4}) then {
            _now params ["_nx", "_ny", "_nw", "_nh"];
            _mine params [["_mx", -9999], ["_my", -9999], ["_mw", 0], ["_mh", 0]];

            // did somebody else move this? compare against what we last set. if it has changed, a render function has
            // deliberately repositioned it, and that is now the truth, so adopt it as the new resting place.
            if ((abs (_nx - _mx)) > 1e-6 || {(abs (_ny - _my)) > 1e-6}
                || {(abs (_nw - _mw)) > 1e-6} || {(abs (_nh - _mh)) > 1e-6}) then {
                if ((_nx isEqualType 0) && {finite _nx} && {finite _ny}) then {
                    _base = [_nx - _lox, _ny - _loy, _nw, _nh];
                    _x set [1, _base];
                };
            };

            _base params ["_bx", "_by", "_bw", "_bh"];
            private _set = [_bx + _dx, _by + _dy, _bw, _bh];
            _c ctrlSetPosition _set;
            _c ctrlCommit 0;
            _x set [2, _set];
        };
    };
} forEach _known;

uiNamespace setVariable [_storeKey + "_off", [_dx, _dy]];
[_dx, _dy]
