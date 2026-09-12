/* Phase 121: prepared-syringe carousel navigation.
   Carousel changes are now instantaneous. The previous 220 ms multi-control interpolation committed dozens of
   controls for every A/D/click step and produced client-side frame hitches on some systems. Selection semantics are
   unchanged; only decorative movement interpolation/nudging is removed. */
disableSerialization;
params [["_dir", 1, [0]]];
if (_dir == 0) exitWith {};
_dir = if (_dir < 0) then {-1} else {1};
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View", "syringe"]) != "body"}) exitWith {};
if (uiNamespace getVariable ["ACME_SK_TagEditMode", false]) exitWith {};
if (uiNamespace getVariable ["ACME_SK_InjectionBusy", false]) exitWith {};

private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _n = count _store;
if (_n < 1) exitWith {};

// Preserve the old navigation presentation/selection policy, but commit the result immediately.
uiNamespace setVariable ["ACME_SK_CarouselExpanded", true];
uiNamespace setVariable ["ACME_SK_CarouselHover", false];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt", diag_tickTime + 1.35];
uiNamespace setVariable ["ACME_SK_DiscardArmedId", ""];
uiNamespace setVariable ["ACME_SK_CarouselBusy", false];

private _idx = [_store] call ACME_fnc_skSelectedIndex;
if (_idx < 0) then {_idx = 0;};
if (_n > 1) then {
    private _new = ((_idx + _dir) mod _n);
    if (_new < 0) then {_new = _new + _n;};
    [_new, _store] call ACME_fnc_skSelectStored;
};
uiNamespace setVariable ["ACME_SK_EpiDoseChoice", 0];
uiNamespace setVariable ["ACME_SK_SelFlush", ""];
uiNamespace setVariable ["ACME_SK_SiteIdx", -1];
[0] call ACME_fnc_skDynamicLayout;
[0] call ACME_fnc_skCarouselRender;
call ACME_fnc_skBuildHotspots;
