// Crossfade the staged tongue views as the laryngoscope opens the airway.
// Exactly two adjacent tongue frames are visible during a transition. Their alpha values are complementary,
// so the old frame actually fades out while the next one fades in rather than stacking a new frame over an
// always-opaque old one. This restores the visible tongue motion between each laryngoscopy stage.
params ["_dlg", ["_open", 0]];
if (isNull _dlg) exitWith {};
if (!(_open isEqualType 0) || {!(finite _open)}) then { _open = 0; };
_open = (_open max 0) min 1;

private _frames = [87801, 87851, 87852, 87853];
private _t = ((_open * 3) max 0) min 3;
if (_t >= 2.999) exitWith {
    {(_dlg displayCtrl _x) ctrlSetTextColor [1,1,1,([0,1] select (_forEachIndex == 3))];} forEach _frames;
};
private _i = (floor _t) max 0 min 2;
private _f = (_t - _i) max 0 min 1;
// Smoothstep avoids a mechanical linear dissolve while remaining a genuine crossfade.
private _blend = _f * _f * (3 - (2 * _f));
{
    private _a = switch (true) do {
        case (_forEachIndex == _i): {1 - _blend};
        case (_forEachIndex == (_i + 1)): {_blend};
        default {0};
    };
    (_dlg displayCtrl _x) ctrlSetTextColor [1,1,1,_a];
} forEach _frames;
