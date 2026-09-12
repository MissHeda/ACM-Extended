/* Keep the visual pass after every procedural early return. */
private _acmeNVArgs = if (isNil "_this") then {[]} else {_this};
_acmeNVArgs call {
// the per-frame plunger mover. while grabbed, toggled by clicking the barrel, the plunger follows the mouse y.
// the needle is at the bottom, so pushing down lowers the volume, expelling, and pulling up raises it, drawing. that
// is the opposite of the old build.
// there are two phases. with the saline not yet wasted, where the base is below 0, it is a free drag from 0 to the
// size, to set the volume to keep. with a medication selected, where the base is 0 or above, the drag is floored at
// the saline base and the volume above it is the drawn med.
// it self-cancels when the dialog closes.
params ["_args", "_handle"];

private _display = uiNamespace getVariable ["ACME_SK_DLG", displayNull];
if (isNull _display) exitWith { [_handle] call CBA_fnc_removePerFrameHandler; };

// the darkness is drawn first, above every branch below, for the same reason it is first in the chest seal,
// the iv and the thoracostomy ticks. anything placed after a branch that can bail out only draws in the states
// that happen to fall all the way through, which reads as the lighting working intermittently.

if (uiNamespace getVariable ["ACME_SK_Grab", false]) then {
    private _geo = uiNamespace getVariable ["ACME_SK_Geo", []];
    if !(_geo isEqualTo []) then {
        _geo params ["_bx", "_byTop", "_bw", "_bh"];
        private _size = uiNamespace getVariable ["ACME_SK_Size", 10];
        private _mouseY = getMousePosition select 1;
        private _rel = 0;
        if (_bh > 0) then { _rel = 1 - (((_mouseY - _byTop) / _bh) max 0 min 1); };  // push DOWN -> less
        private _vol  = _size * _rel;
        private _base = uiNamespace getVariable ["ACME_SK_SalineBase", -1];
        if (_base >= 0) then {
            _vol = _vol max _base;  // can't draw below the saline base
            uiNamespace setVariable ["ACME_SK_EpiMl", (_vol - _base) max 0];
        };
        uiNamespace setVariable ["ACME_SK_Vol", _vol];
    };
};

call ACME_fnc_syringeKitRender;

};
[uiNamespace getVariable ["ACME_SK_DLG", displayNull], [], "ACME_SK_Shade"] call ACME_fnc_darknessShade;
[uiNamespace getVariable ["ACME_SK_DLG", displayNull]] call ACME_fnc_minigameVisionTick;
