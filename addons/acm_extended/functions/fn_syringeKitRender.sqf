// repaint the procedural syringe, meaning the barrel fill, the plunger and the rod, and the volume readout, from
// the current acme_sk_* state.
// the needle is at the bottom: a full syringe is the plunger pulled up with fluid filling the barrel below it, and
// pushing the plunger down expels, or wastes, fluid.
// the geometry is in screen fractions, and ACME_SK_Geo, as [barrelx, barreltopy, barrelw, barrelh], is laid down
// once in onload.
private _display = uiNamespace getVariable ["ACME_SK_DLG", displayNull];
if (isNull _display) exitWith {};

private _geo = uiNamespace getVariable ["ACME_SK_Geo", []];
if (_geo isEqualTo []) exitWith {};
_geo params ["_bx", "_byTop", "_bw", "_bh"];

private _size = uiNamespace getVariable ["ACME_SK_Size", 10];
private _vol  = (uiNamespace getVariable ["ACME_SK_Vol", 0]) max 0 min _size;
private _epi  = uiNamespace getVariable ["ACME_SK_EpiMl", 0];
private _base = uiNamespace getVariable ["ACME_SK_SalineBase", -1];

private _fillFrac = 0;
if (_size > 0) then {_fillFrac = _vol / _size};
// the top face of the fluid: full puts the plunger at the barrel top and empty puts it at the bottom, the
// needle.
private _plungerY = _byTop + (_bh * (1 - _fillFrac));

// the fluid column: from the plunger face down to the needle, at the barrel bottom. it sits behind the real syringe
// texture, so it reads as liquid inside the glass, and the alpha is bumped to show through cleanly.
private _ctrlFluid = _display displayCtrl 86313;
if (!isNull _ctrlFluid) then {
    _ctrlFluid ctrlSetPosition [_bx, _plungerY, _bw, (_bh * _fillFrac)];
    private _col = if (_epi > 0) then {["danger", 0.85] call ACME_fnc_a11yColor} else {["info", 0.82] call ACME_fnc_a11yColor};
    _ctrlFluid ctrlSetTextColor _col;
    _ctrlFluid ctrlCommit 0;
    _ctrlFluid ctrlShow (_fillFrac > 0.001);
};

// the plunger stopper: a dark rubber bar across the barrel at the fluid face, drawn over the texture so the level
// reads crisply and the plunger appears to move as you drag.
private _plH = _bh * 0.03;
private _ctrlPlunger = _display displayCtrl 86314;
if (!isNull _ctrlPlunger) then {
    _ctrlPlunger ctrlSetPosition [_bx - (_bw * 0.08), _plungerY - (_plH / 2), _bw * 1.16, _plH];
    _ctrlPlunger ctrlCommit 0;
};

// the plunger rod and thumb rest come from the real syringe texture now, and the old procedural rod control, 86315,
// is hidden in onload.

// the numeric readout, with the saline and med split once epi is being drawn.
private _ctrlVol = _display displayCtrl 86321;
if (!isNull _ctrlVol) then {
    private _txt = format ["%1 mL", (_vol toFixed 1)];
    if (_base >= 0 && _epi > 0) then {
        _txt = format ["%1 mL  (%2 sal + %3 epi)", (_vol toFixed 1), (_base toFixed 1), (_epi toFixed 1)];
    };
    _ctrlVol ctrlSetText _txt;
};
