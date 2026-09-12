/*
 * Local medical-menu presentation state. ACE recreates its display after treatments,
 * so display variables alone cannot remember which sections the provider opened.
 *
 * ["read", patient] returns a copy of that patient's open group keys
 * ["toggle", patient, groupKey] changes one explicit decision and returns a copy
 *
 * Tabs, selected body parts, temporary eligibility and grouping settings do not
 * modify these decisions. Keep at most 32 recently viewed patients and 256 keys
 * per patient; deleted patient handles are discarded, deceased patients retained.
 * No patient variables, network events, treatment state or profile data are written.
 */
params [['_mode', 'read', ['']], ['_patient', objNull, [objNull]], ['_key', '', ['']]];
if (isNull _patient || {!(_mode in ['read', 'toggle'])}) exitWith {[]};

private _cache = uiNamespace getVariable ['ACME_menuDropdownCache', []];
if !(_cache isEqualType []) then {_cache = [];};
_cache = _cache select {
    _x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType objNull}
    && {!isNull (_x select 0)} && {(_x select 1) isEqualType []}
};
private _index = _cache findIf {(_x select 0) isEqualTo _patient};
private _open = [];
if (_index >= 0) then {
    _open = +((_cache deleteAt _index) select 1);
};
_open = (_open select {_x isEqualType '' && {_x != ''}}) arrayIntersect _open;
if (_mode == 'toggle' && {_key != ''}) then {
    if (_key in _open) then {_open = _open - [_key];} else {_open pushBack _key;};
};
if (count _open > 256) then {_open = _open select [(count _open) - 256];};
_cache pushBack [_patient, +_open];
if (count _cache > 32) then {_cache deleteRange [0, (count _cache) - 32];};
uiNamespace setVariable ['ACME_menuDropdownCache', _cache];
+_open
