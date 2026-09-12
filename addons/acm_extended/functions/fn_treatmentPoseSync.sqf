/* CBA global/JIP receiver for every frozen provider hold (stethoscope, pulse, roll). switchMove seeks the
 * normalized time when the owner could compute one; a phase below zero means freeze in place with no seek.
 * setAnimSpeedCoef is local on each machine, including joining providers. */
params ["_medic", "_epoch", "_operation", ["_main", ""], ["_phase", 0], ["_owner", -1]];
if (isNull _medic) exitWith {};
private _record = _medic getVariable ["ACME_treatmentPoseRemote", [-1, "", -1]];
if ((_record select 0) > _epoch) exitWith {};
if ((_record select 0) == _epoch && {(_record select 1) == "release"}) exitWith {};
if (_operation == "hold" && {local _medic} && {owner _medic == _owner}) exitWith {
    // B57: the owner controller already froze and sought this exact frame before broadcasting. Re-applying the
    // same switchMove through the global event can look like a one-frame animation restart.
    _medic setAnimSpeedCoef 0;
};
// The JIP event and object variables have separate delivery paths. Wait for the
// atomic episode record when it is not known yet; unknown is not a cancelled hold.
private _episode = _medic getVariable ["ACME_treatmentPoseEpisode", [-1, false]];
if (_operation == "hold" && {(_episode select 0) < _epoch}) exitWith {
    [{
        params ["_medic", "_epoch"];
        isNull _medic || {((_medic getVariable ["ACME_treatmentPoseEpisode", [-1, false]]) select 0) >= _epoch}
    }, {
        _this call ACME_fnc_treatmentPoseSync;
    }, _this, 3] call CBA_fnc_waitUntilAndExecute;
};
if ((_record select 2) >= 0) then {
    [(_record select 2)] call CBA_fnc_removePerFrameHandler;
    _medic setAnimSpeedCoef 1;
};
_medic setVariable ["ACME_treatmentPoseRemote", [_epoch, "release", -1]];
if (_operation != "hold") exitWith {};
if (!alive _medic || {_medic getVariable ["ACE_isUnconscious", false]}
    || {owner _medic != _owner} || {!isNull objectParent _medic}
    || {!((_medic getVariable ["ACME_treatmentPoseEpisode", []]) isEqualTo [_epoch, true])}) exitWith {};
// Seek first, then freeze. If switchMove resets animation speed internally, the final command still leaves the
// exact requested frame stopped. An unknown owner duration arrives as phase -1 and only freezes in place.
if (_phase >= 0) then {_medic switchMove [_main, _phase, 1, false];};
_medic setAnimSpeedCoef 0;
private _record = [_epoch, "hold", -1];
_medic setVariable ["ACME_treatmentPoseRemote", _record];
private _pfh = [{
    params ["_args", "_pfh"];
    _args params ["_medic", "_epoch", "_main", "_phase", "_owner"];
    private _record = _medic getVariable ["ACME_treatmentPoseRemote", [-1, "", -1]];
    if (isNull _medic || {(_record select 0) != _epoch} || {(_record select 1) != "hold"}) exitWith {
        [_pfh] call CBA_fnc_removePerFrameHandler;
    };
    private _episodeActive = (_medic getVariable ["ACME_treatmentPoseEpisode", []]) isEqualTo [_epoch, true];
    private _hardRelease = !alive _medic
        || {_medic getVariable ["ACE_isUnconscious", false]}
        || {!isNull objectParent _medic}
        || {owner _medic != _owner}
        || {!_episodeActive};
    private _lostFrame = toLower animationState _medic != toLower _main;
    if (_hardRelease || {_lostFrame}) exitWith {
        _medic setAnimSpeedCoef 1;
        // A transient animation replacement is not the end of the stethoscope episode. Mark it lost so the
        // owner can broadcast the held frame again. Only a real episode/context end becomes an irreversible release.
        _medic setVariable ["ACME_treatmentPoseRemote", [_epoch, ["lost", "release"] select _hardRelease, -1]];
        [_pfh] call CBA_fnc_removePerFrameHandler;
        // Ownership transfer aborts the old provider's theatre on the new owner too.
        if (local _medic && {owner _medic != _owner}) then {
            if ((_medic getVariable ["ACME_treatmentPoseEpisode", []]) isEqualTo [_epoch, true]) then {
                _medic setVariable ["ACME_treatmentPoseEpisode", [_epoch, false], true];
            };
            [format ["ACME_treatmentPose_%1_%2", netId _medic, _epoch]] call CBA_fnc_removeGlobalEventJIP;
            if (alive _medic && {!(_medic getVariable ["ACE_isUnconscious", false])}
                && {isNull objectParent _medic} && {toLower animationState _medic == toLower _main}) then {
                [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;
            };
        };
    };
    // A late starter-treatment speed reset must not resume the held pose on peers.
    if (getAnimSpeedCoef _medic != 0) then {
        if (_phase >= 0) then {_medic switchMove [_main, _phase, 1, false];};
        _medic setAnimSpeedCoef 0;
    };
}, 0, [_medic, _epoch, _main, _phase, _owner]] call CBA_fnc_addPerFrameHandler;
_record set [2, _pfh];
