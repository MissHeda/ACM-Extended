// the ventilator panel color. every color the screen of the sparrow draws passes through here.
// call it as [_rgba] call ACME_fnc_ventColor.
// two things happen, in this order, and the order matters.
// 1. the display brightness is applied, because it is a property of the physical screen.
// 2. the colorblind correction is applied on the result, because that is a property of the viewer.
// doing it the other way round would let a correction undo the dimming and light the panel back up, which would
// defeat the entire point of the night setting.
// the night setting is the interesting one. per the ventway manual, brightness lives at main MENU, ADV SETTINGS,
// BRIGHTNESS, and on the robust, military, model there is an additional low setting that drops the brightness and
// the alarm volume together. that pairing is deliberate on the real device: the two things that give away a
// position at night are the glow and the noise, so they are reduced as one action.
// here, that lowest setting renders the screen essentially unreadable to the naked eye. it is not a cosmetic dim.
// it is meant to be unusable without goggles, so that turning it on is a real tactical tradeoff rather than a free
// option, and so that a medic who forgets to turn it back up in daylight notices immediately.

params ["_c"];
if !(_c isEqualType []) exitWith { [1,1,1,1] };
if ((count _c) < 3) exitWith { [1,1,1,1] };

private _a = _c param [3, 1];

// brightness is no longer applied here. it is applied once, by the veil over the whole screen, idc 87704, driven
// in fn_ventpaneltick, because a color resolver can only reach colors the addon itself draws: the white bars of
// the inlay, the face and the screen substrate are textures and literals and were never dimmed by it. that is why
// night used to leave a bright white bar sitting above a dark screen.
// dimming in both places would darken addon-drawn color twice and everything else once, so this function does
// color correction only.

private _r = _c select 0;
private _g = _c select 1;
private _b = _c select 2;

// the colorblind correction. it is deliberately not "protect" here, because that lifts a color back above a
// luminance floor, which is right for menu text and would fight the night setting, and the veil above this is what
// the night setting works through now.
[[_r, _g, _b, _a]] call ACME_fnc_cbColor
