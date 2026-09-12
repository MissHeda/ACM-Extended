/* B59 compatibility callback for old development dialogs. The visible Drawn list no longer exists; if an older
   control still dispatches this callback, translate its row index into the stable shared syringe selection. */
params ["_ctrl", "_index"];
if (_index < 0) exitWith {};
private _storeIdx = _ctrl lbValue _index;
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
if (([_storeIdx,_store] call ACME_fnc_skSelectStored) < 0) exitWith {};
uiNamespace setVariable ["ACME_SK_EpiDoseChoice", 0];
uiNamespace setVariable ["ACME_SK_SelFlush", ""];
uiNamespace setVariable ["ACME_SK_SiteIdx", -1];
private _view = uiNamespace getVariable ["ACME_SK_View","syringe"];
if (_view == "body") then {call ACME_fnc_skBodySyringeRender; call ACME_fnc_skBuildHotspots;};
if (_view == "carousel") then {call ACME_fnc_skCarouselRender;};
