/* B66: clicking a visible carousel syringe uses the same animated step motion as A/D instead of snapping the stable
   selection index.  Far-left/far-right entries are two sequential steps; the center click simply promotes/holds the
   carousel. */
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
    [_dir] call ACME_fnc_skCarouselMove;
    if (abs _offset > 1) then {
        [{params ["_dir"]; [_dir] call ACME_fnc_skCarouselMove;},[_dir],0.24] call CBA_fnc_waitAndExecute;
    };
};

// Clicking the selected center syringe still toggles normal browsing. A staged administration target keeps the
// carousel promoted until Push/Inject is confirmed or the provider leaves Body Map.
private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
if (_pending isEqualType [] && {count _pending >= 3}) exitWith {
    uiNamespace setVariable ["ACME_SK_CarouselExpanded",true];
    uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
};
call ACME_fnc_skCarouselToggle;
