// keep the access site column of the Place IV module honest about the limb that is selected.
// call it as [] call ACME_fnc_zeusIVDialogSite, from the onLoad and from the LBSelChanged of both lists.
//
// THE COLUMN HOLDS FIVE ROWS AND ONLY SOME OF THEM APPLY.
//   0 Upper, 1 Middle, 2 Lower   an arm or a leg. they are heights up the limb.
//   3 Left, 4 Right              the neck. the external jugular has a SIDE and no height at all.
// the rows that do not apply are greyed and cannot be selected, rather than hidden, so a curator can see that the
// neck takes a side and a limb does not.
// the previous version listed Upper, Middle and Lower whatever the limb, and a line of hint text underneath said
// that on the neck Upper meant left and Middle meant right. that is a mapping the operator had to hold in their
// head while looking at a word that said something else.
//
// A GREYED ROW CANNOT BE LEFT SELECTED.
// an RscListBox has a per-row colour and no per-row disable, so a click still lands on a greyed row. this runs
// from the LBSelChanged of the site list as well, and bounces a selection that lands on one back to the first
// valid row. it is the same shape as ACME_vent_listLocked on the ventilator: drawn, and excluded from the
// selection.
disableSerialization;
private _d = uiNamespace getVariable ["ACME_IVModule_display", displayNull];
if (isNull _d) then { _d = findDisplay 87900; };
if (isNull _d) exitWith {};

private _limb = _d displayCtrl 87901;
private _site = _d displayCtrl 87902;
if (isNull _limb || {isNull _site}) exitWith {};

// row 4 of the limb list is the neck. it is the external jugular.
private _isEJ = (lbCurSel _limb) == 4;

private _live = if (_isEJ) then { [3, 4] } else { [0, 1, 2] };
private _grey = [0.42, 0.42, 0.42, 1];
private _lit  = [1, 1, 1, 1];
for "_i" from 0 to 4 do {
    _site lbSetColor [_i, (if (_i in _live) then { _lit } else { _grey })];
};

// a selection sitting on a greyed row moves to the first row that applies. the default for a limb is Middle,
// which is the antecubital fossa, and the default for the neck is Left, because there has to be one and the two
// sides are equivalent.
private _sel = lbCurSel _site;
if !(_sel in _live) then {
    _site lbSetCurSel (if (_isEJ) then { 3 } else { 1 });
};
