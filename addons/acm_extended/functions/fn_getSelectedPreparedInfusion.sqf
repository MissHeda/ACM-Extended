private _display = findDisplay 86000;
private _entries = ACE_player getVariable ["ACME_infusion_PreparedBags", []];
if (_entries isEqualTo []) exitWith {[-1, []]};

private _index = missionNamespace getVariable ["ACME_infusion_SelectedPreparedIndex", -1];

if (!isNull _display) then {
    private _ctrlList = _display displayCtrl 86127;
    if (!isNull _ctrlList) then {
        private _row = lbCurSel _ctrlList;
        if (_row >= 0) then {
            private _value = _ctrlList lbValue _row;
            if (_value >= 0) then {_index = _value};
        };
    };
};

if (_index < 0 || {_index >= count _entries}) exitWith {[-1, []]};
[_index, _entries select _index]
