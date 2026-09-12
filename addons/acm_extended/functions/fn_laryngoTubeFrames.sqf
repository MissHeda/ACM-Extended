// the et tube being pushed in, as a six-stage crossfade.
// there are six stacked tube layers, from f1 entering the field to f6 seated through the cords. as the medic clicks
// and drags the tube in, the push depth drives this crossfade so the tube reads as being fed deeper, passing the
// cords on the way. it is the same two-state crossfade the tongue uses: only the current stage and the next are
// ever visible, so the earlier, shallower stage does not sit opaque underneath and freeze the tube half-in.
// call it as [_dlg, _depth] call ACME_fnc_laryngoTubeFrames, where a _depth of 0 is just entering, at f1, and 1 is
// seated, at f8.
params ["_dlg", ["_depth", 0]];
if (isNull _dlg) exitWith {};
if (!(_depth isEqualType 0) || {!(finite _depth)}) then { _depth = 0; };
_depth = (_depth max 0) min 1;

private _frames = [87900, 87901, 87902, 87903, 87904, 87905, 87906, 87907];  // f1 through f8, in draw order.

// hide the blocked frame. 87908 is the will-not-pass tube, shown when the cords are unreachable. nothing has ever
// hidden it again, so once it appeared it stayed on screen over every real tube frame for the rest of the
// procedure. any call that draws a genuine tube stage is by definition a tube that is passing, so it clears.
private _blockedUntilB52 = uiNamespace getVariable ["ACME_laryngo_tubeBalkUntil", 0];
if (diag_tickTime < _blockedUntilB52) exitWith {
    {(_dlg displayCtrl _x) ctrlSetTextColor [1,1,1,0];} forEach _frames;
    (_dlg displayCtrl 87908) ctrlSetTextColor [1,1,1,1];
};
(_dlg displayCtrl 87908) ctrlSetTextColor [1, 1, 1, 0];

// always a whole frame. a crossfade that stops halfway leaves two tube stages ghosted over each other, and a tube
// is a solid object: it is at one depth or the next, never smeared between them.
// the depth itself still carries the momentum from the wheel, so the feel is unchanged. what changes is that the
// picture resolves: as the tube coasts, whichever stage the crossfade is closest to is the one that is drawn,
// solid, and it flips forward or backward at the halfway point. that is what makes it read as a tube sliding
// through detents rather than a dissolve between two pictures.
private _t = _depth * 7;  // 0 to 7 across the eight stages.
private _i = (round _t) max 0 min 7;

{
    (_dlg displayCtrl _x) ctrlSetTextColor [1, 1, 1, ([0, 1] select (_forEachIndex == _i))];
} forEach _frames;
