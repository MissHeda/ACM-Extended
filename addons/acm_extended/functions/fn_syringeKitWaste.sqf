// the waste button. it locks the current plunger volume as the saline base, and the difference from full is the
// wasted volume. it is only meaningful while a flush is loaded and not yet wasted.
private _source = uiNamespace getVariable ["ACME_SK_Source", ""];
if (_source != "Saline") exitWith {
    ["Load a Saline Flush before wasting."] call ACME_fnc_syringeKitInfo;
};
if ((uiNamespace getVariable ["ACME_SK_SalineBase", -1]) >= 0) exitWith {
    ["Saline base already locked. Pick a medication to draw on top."] call ACME_fnc_syringeKitInfo;
};

private _size = uiNamespace getVariable ["ACME_SK_Size", 10];
private _vol  = uiNamespace getVariable ["ACME_SK_Vol", 0];
private _wasted = (_size - _vol) max 0;
uiNamespace setVariable ["ACME_SK_SalineBase", _vol];
uiNamespace setVariable ["ACME_SK_Grab", false];
[format ["Wasted %1 mL. %2 mL saline locked.", (_wasted toFixed 1), (_vol toFixed 1)]] call ACME_fnc_syringeKitInfo;
call ACME_fnc_syringeKitRender;
