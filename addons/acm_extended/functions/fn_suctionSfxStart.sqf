// the accuvac and suction-bag sfx: start a looping positional suction sound on the medic for the duration of the
// suction treatment.
// using the medic as the anchor keeps the sound alive if the casualty dies during the action. it is stored on the
// medic so the callback success or failure can stop it.
params ["_medic", "_patient"];
if (isNull _medic) exitWith {};

private _duration = if (!isNull _patient && {!isNil "ACM_airway_fnc_getSuctionTime"}) then {
    [_patient] call ACM_airway_fnc_getSuctionTime
} else {
    10
};
if (!isNull _patient) then { [_patient, _duration] call ACME_fnc_markImportantSfx; };

private _old = _medic getVariable ["ACME_suction_sfxSource", objNull];
if (!isNull _old) then { deleteVehicle _old; };
private _src = createSoundSource ["ACM_Suction_SoundSource", getPosATL _medic, [], 0];
if (!isNull _src) then {
    _src attachTo [_medic, [0, 0.12, 0.25]];
};
_medic setVariable ["ACME_suction_sfxSource", _src];
