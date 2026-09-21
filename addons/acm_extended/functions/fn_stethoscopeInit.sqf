// All input, audio and cursor state belongs to this display instance.
disableSerialization;
params ["_display"];
if (isNull _display) exitWith {};
[_display,"front"] call ACME_fnc_stethoscopeSetView;
_display setVariable ["ACME_stethNextLungUpdate",-1];
_display setVariable ["ACME_stethCursor",getMousePosition];
_display setVariable ["ACME_stethLastFrame",diag_tickTime];
_display setVariable ["ACME_stethNextBeat",-1];
_display setVariable ["ACME_stethNextBreath",-1];
private _bell = _display displayCtrl 81002;
private _size = (ctrlPosition _bell) select [2,2];
_display setVariable ["ACME_stethBellSize",_size];
getMousePosition params ["_x","_y"];
_bell ctrlSetPosition [_x - (_size select 0)/2,_y - (_size select 1)/2];
_bell ctrlCommit 0;
_bell ctrlEnable false;
private _down = {
    params ["_source","_button"];
    if (_button != 0) exitWith {false};
    private _d = if (_source isEqualType controlNull) then {ctrlParent _source} else {_source};

    // Use the same absolute GUI cursor source as the original working bell implementation.
    // Do not consume LMB: contact state is ours, cursor motion remains Arma's.
    (ctrlPosition (_d displayCtrl 81006)) params ["_bx","_by","_bw","_bh"];
    getMousePosition params ["_mx","_my"];
    if (_mx >= _bx && {_mx <= _bx + _bw} && {_my >= _by} && {_my <= _by + _bh}) exitWith {false};

    _d setVariable ["ACME_stethPressed",true];

    // Restore the pre-regression input contract from the last stable held-bell implementation. Consuming only
    // the press prevents an underlying RscButton/RscPicture from capturing LMB and freezing Arma's GUI cursor
    // while the bell is held. This does NOT restore click-to-pick-up: the bell still follows the cursor at all
    // times and MouseButtonUp still releases contact normally.
    true
};
private _up = {
    params ["_source","_button"];
    if (_button != 0) exitWith {false};
    private _d = if (_source isEqualType controlNull) then {ctrlParent _source} else {_source};
    _d setVariable ["ACME_stethPressed",false];
    false
};
_display displayAddEventHandler ["MouseButtonDown",_down];
_display displayAddEventHandler ["MouseButtonUp",_up];
// Static picture/text controls cover the panel. Receive releases over any of them too.
{
    _x ctrlAddEventHandler ["MouseButtonDown",_down];
    _x ctrlAddEventHandler ["MouseButtonUp",_up];
} forEach ((allControls _display) select {!(ctrlIDC _x in [81002,81006])});

// Independent local emitters preserve each playing clip's phase as the bell crosses the chest.
// say3D follows its emitter. Moving each emitter along the camera's vertical axis changes
// native distance attenuation continuously, without restarting samples or fading the world mixer.
private _channels = [];
// Right/left breath, heart, then right/left basal crackles.
for "_i" from 0 to 4 do {
    private _emitter = "#particlesource" createVehicleLocal (positionCameraToWorld [0,22,0]);
    _channels pushBack [_emitter,objNull,0];
};
_display setVariable ["ACME_stethChannels",_channels];
