/* B68: select the syringe that was just saved, but stay on the MAIN Draw Syringe page.
   Saving/preparing a syringe must never force the provider into Body Map/carousel. */
params [["_deferToReopen", false, [false]]];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
if (_store isEqualTo []) exitWith {false};
private _idx = (count _store) - 1;
[_idx, _store] call ACME_fnc_skSelectStored;
uiNamespace setVariable ["ACME_SK_OpenBodyAfterSaveId", ""];
uiNamespace setVariable ["ACME_SK_SiteIdx", -1];
uiNamespace setVariable ["ACME_SK_EpiDoseChoice", 0];
uiNamespace setVariable ["ACME_SK_SelFlush", ""];
uiNamespace setVariable ["ACME_SK_CarouselExpanded", false];
uiNamespace setVariable ["ACME_SK_CarouselHover", false];
uiNamespace setVariable ["ACME_SK_CarouselZoneHover", false];
uiNamespace setVariable ["ACME_SK_TagEditMode", false];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt", 0];
call ACME_fnc_skPendingTagReset;
uiNamespace setVariable ["ACME_SK_View", "syringe"];
private _d = findDisplay 84000;
if (!isNull _d) then {call ACME_fnc_skSetView;};
true
