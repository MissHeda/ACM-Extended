// clear the patient-side i-gel EMMA routes owned by this medic. it is used whenever the reusable EMMA is moved back
// to the BVM or removed.
// _this is [_medic].
params [["_medic", objNull]];

if (isNull _medic) exitWith {false};

private _uid = getPlayerUID _medic;
private _range = missionNamespace getVariable ["ACME_emma_igelRange", 5];
private _lastPatient = _medic getVariable ["ACME_emma_lastContactPatient", objNull];
private _cleared = false;

private _clearPatient = {
    params [["_p", objNull]];
    if (isNull _p) exitWith {false};
    if !(_p getVariable ["ACME_emma_igelAttached", false]) exitWith {false};

    [_p, false] call ACME_fnc_emmaIGelStateCommit;
    true
};

// first clear the last-contact patient, even if the range moved or staled.
if (!isNull _lastPatient) then {
    if ([_lastPatient] call _clearPatient) then { _cleared = true; };
};

// then clear every route clearly owned by this medic. if the UID is unavailable, only clear the nearby and last
// routes, so multiplayer clients cannot accidentally strip the i-gel EMMA of another medic.
{
    if (_x getVariable ["ACME_emma_igelAttached", false]) then {
        private _attachedBy = _x getVariable ["ACME_emma_igelAttachedByUID", ""];
        private _owned = false;
        if (_uid isNotEqualTo "") then {
            _owned = (_attachedBy isEqualTo _uid) || {_attachedBy isEqualTo "" && {(_x isEqualTo _lastPatient) || {(_medic distance _x) <= _range}}};
        } else {
            _owned = (_attachedBy isEqualTo "") || {(_x isEqualTo _lastPatient) || {(_medic distance _x) <= _range}};
        };
        if (_owned) then {
            if ([_x] call _clearPatient) then { _cleared = true; };
        };
    };
} forEach allUnits;

_medic setVariable ["ACME_emma_route", "none", false];
_medic setVariable ["ACME_emma_capPatient", objNull, false];
_medic setVariable ["ACME_emma_lastPatient", objNull, false];
_medic setVariable ["ACME_emma_lastBag", -1e9, false];
_medic setVariable ["ACME_emma_lastContactPatient", objNull, false];
_medic setVariable ["ACME_emma_lastContactTime", -1e9, false];

private _layer = "ACME_EMMA" call BIS_fnc_rscLayer;
_layer cutText ["", "PLAIN"];
uiNamespace setVariable ["ACME_EMMA_DLG", displayNull];

_cleared
