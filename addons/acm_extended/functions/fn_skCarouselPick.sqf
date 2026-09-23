/* Carousel movement is immediate. Resolve the clicked offset in one selection transaction;
   a delayed second step could otherwise navigate a reopened dialog or another provider's store.
   The center click keeps its existing browsing/staged-target policy. */
params [["_offset", 0, [0]]];
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body"}) exitWith {};
if (uiNamespace getVariable ["ACME_SK_TagEditMode",false]) exitWith {};
private _colorList = _d displayCtrl 84471;
if (!isNull _colorList) then {_colorList lbSetCurSel -1; _colorList ctrlShow false;};
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _n = count _store;
if (_n < 1) exitWith {};

if (_offset != 0) exitWith {
    private _dir = if (_offset < 0) then {-1} else {1};
    [_dir, if (abs _offset > 1) then {2} else {1}] call ACME_fnc_skCarouselMove;
};

// Clicking the selected center syringe still toggles normal browsing. A staged administration target keeps the
// carousel promoted until Push/Inject is confirmed or the provider leaves Body Map.
private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
if (_pending isEqualType [] && {count _pending >= 3}) exitWith {
    uiNamespace setVariable ["ACME_SK_CarouselExpanded",true];
    uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
};
call ACME_fnc_skCarouselToggle;
