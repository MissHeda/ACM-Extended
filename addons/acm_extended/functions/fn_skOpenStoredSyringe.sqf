/* B59: self-interaction entry opens by stable syringe ID, never by an array index that can drift. Numeric selectors
   remain accepted for compatibility with older saved callbacks during development. */
params [["_selector",0,[0,""]]];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
if (_store isEqualTo []) exitWith {};
private _idx = [_selector,_store] call ACME_fnc_skSelectStored;
if (_idx < 0) exitWith {};
private _row = _store select _idx;
private _size = _row param [1,10,[0]];
if !(_size in [1,3,5,10]) then {_size = 10;};
uiNamespace setVariable ["ACME_SK_OpenCarouselId", _row param [11,"",[""]]];
ACME_infusion_pendingContext = nil;
[_size] call ACME_fnc_skOpenDraw;
