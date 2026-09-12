/* B60: copy the three transparent-on-tag edit controls into pending preparation state. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d) exitWith {};
private _lines = [];
for "_i" from 0 to 2 do {
    private _t = (ctrlText (_d displayCtrl (84601 + _i))) select [0,25];
    _lines pushBack _t;
    if ((ctrlText (_d displayCtrl (84601 + _i))) != _t) then {(_d displayCtrl (84601 + _i)) ctrlSetText _t;};
};
uiNamespace setVariable ["ACME_SK_PendingTagText", _lines];
