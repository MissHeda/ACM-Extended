/* B59: settle UI selection after the currently selected syringe was fully consumed.
   Keep the nearest remaining syringe active, but clear site/dose transient state so the next syringe cannot be
   administered using stale target state. */
params [["_oldIndex", 0, [0]]];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
uiNamespace setVariable ["ACME_SK_SiteIdx", -1];
uiNamespace setVariable ["ACME_SK_EpiDoseChoice", 0];
uiNamespace setVariable ["ACME_SK_SelFlush", ""];
uiNamespace setVariable ["ACME_SK_PendingInjection", []];
uiNamespace setVariable ["ACME_SK_DiscardArmedId", ""];

if (_store isEqualTo []) then {
    uiNamespace setVariable ["ACME_SK_SelectedSyringeId", ""];
    uiNamespace setVariable ["ACME_SK_SelDrawn", -1];
    uiNamespace setVariable ["ACME_SK_CarouselIdx", -1];
    call ACME_fnc_skRefreshDrawn;
} else {
    [(_oldIndex min ((count _store) - 1)) max 0, _store] call ACME_fnc_skSelectStored;
    call ACME_fnc_skRefreshDrawn;
};
private _d = findDisplay 84000;
if (!isNull _d && {(uiNamespace getVariable ["ACME_SK_View","syringe"]) == "body"}) then {call ACME_fnc_skBuildHotspots;};
