// The server creates/deletes each global hiss exactly once. Handles never depend on a listener.
params ["_patient", "_flow"];
if (!isServer || {isNull _patient}) exitWith {};
private _key = netId _patient;
private _entry = ACME_nrb_soundRegistry getOrDefault [_key, [_patient, objNull, CBA_missionTime]];
private _source = _entry select 1;
if (!_flow || {!alive _patient}) exitWith {
    if (!isNull _source) then { deleteVehicle _source; };
    ACME_nrb_soundRegistry deleteAt _key;
    _patient setVariable ["ACME_nrb_sfxSource", objNull, true];
};
if (isNull _source) then {
    _source = createSoundSource ["ACM_NRB_SoundSource", getPosATL _patient, [], 0];
    if (!isNull _source) then { _source attachTo [_patient, [0, 0.12, 0.25]]; };
    _patient setVariable ["ACME_nrb_sfxSource", _source, true];
};
ACME_nrb_soundRegistry set [_key, [_patient, _source, CBA_missionTime]];
