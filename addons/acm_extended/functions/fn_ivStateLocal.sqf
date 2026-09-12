/* Owner-only partial-view and physical-band updates, scoped to the clinical episode.
   Saved UI rows never set a physical band. They must agree with the owner's band snapshot. */
params ["_patient", "_mode", "_data", "_epoch"];
if (isNull _patient || {!local _patient}
    || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {};
private _parts = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"];
switch (_mode) do {
    case "band": {
        _data params ["_index", "_on", ["_view", "", [""]], ["_band", [], [[]]]];
        if !(_index in [2,3,4,5] && {_on isEqualType true}) exitWith {};
        if (_on && {count _band != 6 || {_view == ""}}) exitWith {};
        private _bp = _parts select _index;
        private _stateName = format ["ACME_IV_BandState_%1", _index];
        private _old = _patient getVariable [_stateName, []];
        if (count _band != 6) then {_band = _old param [3, [false, "middle", [], [], "", ""]];};
        _band = +_band;
        _band set [0, _on];
        private _snapshot = [(_old param [0, 0]) + 1, _on, _view, _band];
        [_patient, format ["ACME_IV_BandOnPart_%1", _index], _on] call ACME_fnc_setVarNet;
        // Clear stale band flags on every face of this limb; keep catheter and prep data.
        private _next = [];
        private _key = format ["%1|%2", _bp, _view];
        private _found = false;
        {
            private _row = +_x;
            private _rowKey = _row param [0, ""];
            if ((_rowKey find (_bp + "|")) == 0 && {count _row == 4}) then {
                private _rowBand = +(_row select 1);
                if (_rowKey == _key && {_on}) then {_rowBand = +_band; _found = true;} else {_rowBand set [0, false];};
                _row set [1, _rowBand];
            };
            _next pushBack _row;
        } forEach (_patient getVariable ["ACME_IV_SiteState", []]);
        if (_on && {!_found}) then {
            _next pushBack [_key, +_band, ["",0,"",16,0.5,0.5,false,0,""], [false,0]];
        };
        [_patient, "ACME_IV_SiteState", _next] call ACME_fnc_setVarNet;
        // Publish geometry, presence and revision together after the clinical flag.
        [_patient, _stateName, _snapshot] call ACME_fnc_setVarNet;
    };
    case "view": {
        _data params ["_key", "_entry"];
        if !(_key isEqualType "" && {_entry isEqualType []}) exitWith {};
        if (count _entry > 0 && {count _entry != 4 || {!((_entry select 0) isEqualTo _key)}}) exitWith {};
        if (count _entry == 4 && {!((_entry select 1) isEqualType []) || {count (_entry select 1) != 6}}) exitWith {};
        private _keyPart = (_key splitString "|") param [0, ""];
        // The close-up EJ view has its own key; it is clinically a head site.
        // Retain that exact key while allowing its unfinished catheter snapshot.
        private _index = _parts find (if (_keyPart == "ej") then {"head"} else {_keyPart});
        if (_index < 0) exitWith {};
        private _current = _patient getVariable ["ACME_IV_SiteState", []];
        private _state = _patient getVariable [format ["ACME_IV_BandState_%1", _index], []];
        private _activeHere = count _state == 4 && {_state select 1} && {_key == format ["%1|%2", _parts select _index, _state select 2]};
        // An idle observer closing must not delete another provider's active band row.
        if (_entry isEqualTo [] && {_activeHere}) exitWith {};
        if (count _entry == 4 && {_index in [2,3,4,5]}) then {
            _entry = +_entry;
            private _band = +(_entry select 1);
            if (count _state == 4) then {
                _band = if (_activeHere) then {+(_state select 3)} else {_band};
                _band set [0, _activeHere];
            } else {
                _band set [0, (_band select 0) && {_patient getVariable [format ["ACME_IV_BandOnPart_%1", _index], false]}];
            };
            _entry set [1, _band];
        };
        private _next = _current select {!((_x select 0) isEqualTo _key)};
        if (count _entry > 0) then {_next pushBack _entry;};
        [_patient, "ACME_IV_SiteState", _next] call ACME_fnc_setVarNet;
    };
};
