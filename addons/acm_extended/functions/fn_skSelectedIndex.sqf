/* B59: resolve the current prepared syringe from its stable ID. If the ID disappeared because the syringe was
   consumed, select the nearest valid presentation index instead of allowing array-index drift to pick a different
   syringe silently. */
params [["_store", [], [[]]], ["_allowFallback", true, [true]]];
if (_store isEqualTo []) then {_store = [ACE_player] call ACME_fnc_skStoreEnsureIds;};
private _n = count _store;
if (_n < 1) exitWith {
    uiNamespace setVariable ["ACME_SK_SelectedSyringeId", ""];
    uiNamespace setVariable ["ACME_SK_SelDrawn", -1];
    uiNamespace setVariable ["ACME_SK_CarouselIdx", -1];
    -1
};

private _id = uiNamespace getVariable ["ACME_SK_SelectedSyringeId", ""];
private _idx = if (_id == "") then {-1} else {_store findIf {(_x param [11, "", [""]]) == _id}};
if (_idx < 0 && {_allowFallback}) then {
    private _legacy = uiNamespace getVariable ["ACME_SK_CarouselIdx", uiNamespace getVariable ["ACME_SK_SelDrawn", 0]];
    if !(_legacy isEqualType 0) then {_legacy = 0;};
    _legacy = (_legacy max 0) min (_n - 1);
    _idx = [_legacy, _store] call ACME_fnc_skSelectStored;
} else {
    if (_idx >= 0) then {
        uiNamespace setVariable ["ACME_SK_SelDrawn", _idx];
        uiNamespace setVariable ["ACME_SK_CarouselIdx", _idx];
    };
};
_idx
