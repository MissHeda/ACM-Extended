// return the tracked infusion-entry index for a currently running dirty-epi bag, or -1.
// the exact recipe is 1 mg of epinephrine in a 1000 ml saline carrier, with drug and bag volume remaining, an open
// roller clamp, and the selected iv or io flow path actually enabled.
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {-1};

private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _bodyParts = missionNamespace getVariable ["ACME_infusion_bodyParts", ["head","body","leftarm","rightarm","leftleg","rightleg"]];
private _result = -1;

{
    private _entry = _x;
    private _medication = _entry param [11, ""];
    private _doseTotal = _entry param [13, 0];
    private _doseRemaining = _entry param [14, 0];
    private _mixVolume = _entry param [9, 0];
    private _type = _entry param [3, ""];
    private _clampPosition = _entry param [22, 0];
    private _dropsPerMinute = _entry param [21, 0];

    private _recipeMatches =
        (_medication == "Epinephrine") &&
        {(toLowerANSI _type) == "saline"} &&
        {abs (_doseTotal - 1) <= 0.001} &&
        {abs (_mixVolume - 1000) <= 2} && {(_entries findIf {(_x param [23, ""]) == (_entry param [23, ""]) && {(_x select 11) != "Epinephrine"} && {(_x select 14) > 0.000001}}) < 0} &&
        {_doseRemaining > 0.0001} &&
        {_clampPosition > 0.0001} &&
        {_dropsPerMinute > 0};

    if (_recipeMatches) then {
        private _bodyPart = _entry param [1, ""];
        private _bagIndex = _entry param [2, -1];
        private _accessSite = _entry param [4, -1];
        private _iv = _entry param [5, true];
        private _bloodType = _entry param [6, -1];
        private _volume = _entry param [7, 0];
        private _freshBloodID = _entry param [8, -1];
        private _lastVolume = _entry param [10, 0];

        private _dirtyContext = [_patient, _bodyPart, _bagIndex, _type, 0, _accessSite, _iv, _bloodType, _volume, _freshBloodID, _lastVolume];
        if ([_dirtyContext] call ACME_fnc_isYLineBagContext) then {continue};

        private _found = [_patient, _bodyPart, _bagIndex, _type, _accessSite, _iv, _bloodType, _volume, _freshBloodID, _lastVolume, (_x param [23, ""])] call ACME_fnc_findTrackedBag;
        if !(_found isEqualTo []) then {
            _found params ["_foundBodyPart", "_foundIndex", "_bag"];
            private _remainingVolume = _bag param [1, 0];
            private _partIndex = _bodyParts find toLowerANSI _foundBodyPart;
            private _flowOn = (_remainingVolume > 0.01) && {_partIndex >= 0} && {_accessSite >= 0};

            if (_flowOn) then {
                if (_iv) then {
                    private _flowArray = _patient getVariable ["ACM_circulation_FluidBagsFlow_IV", [[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1]]];
                    if (_partIndex < count _flowArray) then {
                        private _partFlow = _flowArray select _partIndex;
                        _flowOn = (_accessSite < count _partFlow) && {(_partFlow select _accessSite) > 0};
                    } else {
                        _flowOn = false;
                    };
                } else {
                    private _flowArray = _patient getVariable ["ACM_circulation_FluidBagsFlow_IO", [1,1,1,1,1,1]];
                    _flowOn = (_partIndex < count _flowArray) && {(_flowArray select _partIndex) > 0};
                };
            };

            if (_flowOn) then {_result = _forEachIndex};
        };
    };

    if (_result >= 0) exitWith {};
} forEach _entries;

_result
