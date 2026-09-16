// Build the current site-specific extravasation visual state for one IV limb.
// Output is [[siteIndex,severity], ...], aggregated to the worst active exposure at each site.
// Severity is 1..10 and follows the continuous recovery position once recovery begins.
params [
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "", [""]]
];
if (isNull _patient || {_bodyPart == ""}) exitWith {[]};
private _bp = toLowerANSI _bodyPart;
if !(_bp in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {[]};
private _records = _patient getVariable ["ACME_vesicant_records", []];
private _bySite = createHashMap;
{
    _x params [["_key", ""], ["_recBP", ""]];
    if (toLowerANSI _recBP == _bp && {_key != ""}) then {
        private _cur = _patient getVariable [_key, []];
        if !(_cur isEqualTo []) then {
            private _stage = _cur param [2, -1];
            if (_stage >= 0) then {
                private _site = -1;
                { if ((_key find format ["_site%1", _x]) >= 0) exitWith {_site = _x;}; } forEach [0, 1, 2];
                // Older non-site records are rare; keep them visible at the middle site rather than losing the finding.
                if (_site < 0) then {_site = 1;};
                private _severity = 1;
                if ((count _cur) > 10) then {
                    private _pos = _cur param [10, _stage];
                    if !(_pos isEqualType 0 && {finite _pos}) then {_pos = _stage;};
                    _severity = round (linearConversion [-0.35, 3, _pos, 1, 10, true]);
                } else {
                    private _total = _cur param [0, 0];
                    private _threshold = _cur param [6, 1];
                    if !(_threshold isEqualType 0 && {finite _threshold} && {_threshold > 0}) then {_threshold = 1;};
                    private _ratio = _total / _threshold;
                    _severity = ceil (linearConversion [1, 2, _ratio, 1, 10, true]);
                    private _stageFloor = [1, 4, 7, 9] param [_stage, 1];
                    _severity = _severity max _stageFloor;
                };
                _severity = (_severity max 1) min 10;
                _bySite set [_site, _severity max (_bySite getOrDefault [_site, 0])];
            };
        };
    };
} forEach _records;
private _out = [];
{ private _sev = _bySite getOrDefault [_x, 0]; if (_sev > 0) then {_out pushBack [_x, _sev];}; } forEach [0,1,2];
_out
