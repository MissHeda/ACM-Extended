/* B59: select one prepared syringe by stable ID or by presentation index.
   ACME_SK_SelectedSyringeId is authoritative; legacy index variables are mirrors for older call sites. */
params [["_selector", -1, [0, ""]], ["_store", [], [[]]]];
if (_store isEqualTo []) then {_store = [ACE_player] call ACME_fnc_skStoreEnsureIds;};
private _n = count _store;
if (_n < 1) exitWith {
    uiNamespace setVariable ["ACME_SK_SelectedSyringeId", ""];
    uiNamespace setVariable ["ACME_SK_SelDrawn", -1];
    uiNamespace setVariable ["ACME_SK_CarouselIdx", -1];
    -1
};

private _idx = -1;
if (_selector isEqualType "") then {
    if (_selector != "") then {_idx = _store findIf {(_x param [11, "", [""]]) == _selector};};
} else {
    if (_selector >= 0) then {
        _idx = ((_selector mod _n) + _n) mod _n;
    };
};
if (_idx < 0) exitWith {-1};

private _id = (_store select _idx) param [11, "", [""]];
if (_id == "") exitWith {-1};
uiNamespace setVariable ["ACME_SK_SelectedSyringeId", _id];
uiNamespace setVariable ["ACME_SK_SelDrawn", _idx];
uiNamespace setVariable ["ACME_SK_CarouselIdx", _idx];
_idx
