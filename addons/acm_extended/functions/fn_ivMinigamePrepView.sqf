/* Keep this display's bounded antiseptic controls with their own face.
   Control handles and local drying times never enter the patient/network snapshot. */
disableSerialization;
params [["_mode", "", [""]]];
private _display = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _display) exitWith {};
private _key = format ["%1|%2", uiNamespace getVariable ["ACME_IV_BodyPart", ""], uiNamespace getVariable ["ACME_IV_View", ""]];
private _views = _display getVariable ["ACME_IV_PrepViews", createHashMap];
if (_mode == "leave") exitWith {
    private _ctrls = uiNamespace getVariable ["ACME_IV_PrepCtrls", []];
    private _bruise = uiNamespace getVariable ["ACME_IV_PrepBruise", controlNull];
    _views set [_key, [_ctrls, uiNamespace getVariable ["ACME_IV_PrepCells", createHashMap],
        uiNamespace getVariable ["ACME_IV_PrepTotal", 0], +(uiNamespace getVariable ["ACME_IV_PrepSum", [0,0]]),
        _bruise, !isNull _bruise && {ctrlShown _bruise}]];
    _display setVariable ["ACME_IV_PrepViews", _views];
    {(_x param [0,controlNull]) ctrlShow false;} forEach _ctrls;
    _bruise ctrlShow false;
    uiNamespace setVariable ["ACME_IV_PrepCtrls", []];
    uiNamespace setVariable ["ACME_IV_PrepCells", createHashMap];
    uiNamespace setVariable ["ACME_IV_PrepTotal", 0];
    uiNamespace setVariable ["ACME_IV_PrepSum", [0,0]];
    uiNamespace setVariable ["ACME_IV_PrepBruise", controlNull];
    uiNamespace setVariable ["ACME_IV_PrepLast", []];
};
if (_mode == "clear") exitWith {
    {
        {private _c = _x param [0,controlNull]; if (!isNull _c) then {ctrlDelete _c;};} forEach (_y param [0,[]]);
        private _b = _y param [4,controlNull]; if (!isNull _b) then {ctrlDelete _b;};
    } forEach _views;
    _display setVariable ["ACME_IV_PrepViews", createHashMap];
};
if (_mode != "enter") exitWith {};
private _row = _views getOrDefault [_key, [[],createHashMap,0,[0,0],controlNull,false]];
_row params ["_ctrls", "_cells", "_total", "_sum", "_bruise", "_bruiseShown"];
uiNamespace setVariable ["ACME_IV_PrepCtrls", _ctrls];
uiNamespace setVariable ["ACME_IV_PrepCells", _cells];
uiNamespace setVariable ["ACME_IV_PrepTotal", _total];
uiNamespace setVariable ["ACME_IV_PrepSum", +_sum];
uiNamespace setVariable ["ACME_IV_PrepLast", []];
// Evaluate drying before showing the returned face, to avoid one bright stale frame.
private _hold = missionNamespace getVariable ["ACME_iv_prepHoldSec", 45];
private _fade = missionNamespace getVariable ["ACME_iv_prepFadeSec", 40];
private _tint = missionNamespace getVariable ["ACME_iv_prepTint", [0.80,0.42,0.40]];
{
    private _c = _x param [0,controlNull];
    if (!isNull _c) then {
        private _age = diag_tickTime - (_x param [1,-1]);
        private _k = if ((_x param [1,-1]) < 0 || {_age < _hold}) then {1} else {(1 - ((_age - _hold) / (_fade max 0.1))) max 0};
        _c ctrlSetTextColor [_tint select 0, _tint select 1, _tint select 2, (_x param [2,0.085]) * _k];
        _c ctrlCommit 0;
        _c ctrlShow (_k > 0);
    };
} forEach _ctrls;
if (isNull _bruise) then {
    // This face's bruise remains above the static redness group.
    _bruise = _display ctrlCreate ["ACME_IV_Bruise", -1];
    _bruise ctrlSetText "\acm_extended\ui\iv\bruise_ca.paa";
    _bruise ctrlSetTextColor [1,1,1,0];
    _bruise ctrlCommit 0;
    _bruiseShown = false;
};
_bruise ctrlShow _bruiseShown;
uiNamespace setVariable ["ACME_IV_PrepBruise", _bruise];
