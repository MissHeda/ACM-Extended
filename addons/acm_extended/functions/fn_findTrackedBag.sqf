params ["_patient", "_bodyPart", "_bagIndex", "_type", "_accessSite", "_iv", "_bloodType", "_volume", "_freshBloodID", "_lastVolume", ["_bagUid", ""]];
private _map = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _result = [];
if (_bagUid != "") exitWith {
    {private _part = _x; private _idx = _y findIf {(_x param [8, ""]) isEqualTo _bagUid};
        if (_idx >= 0) exitWith {_result = [_part, _idx, _y select _idx];};
    } forEach _map;
    _result
};
// Legacy callers can select a physical slot, but never use nearest-volume cross-site rebinding.
private _arr = _map getOrDefault [_bodyPart, []];
if (_bagIndex < 0 || {_bagIndex >= count _arr}) exitWith {[]};
private _bag = _arr select _bagIndex;
if ((_bag param [0, ""]) != _type || {(_bag param [3, -1]) != _accessSite} || {(_bag param [4, true]) != _iv} || {(_bag param [5, -1]) != _bloodType} || {(_bag param [6, 0]) != _volume} || {(_bag param [7, -1]) != _freshBloodID}) exitWith {[]};
[_bodyPart, _bagIndex, _bag]
