// All input, audio and cursor state belongs to this display instance.
disableSerialization;
params ["_display"];
if (isNull _display) exitWith {};
_display setVariable ["ACME_stethPressed",false];
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
private _down = {
    params ["_source","_button"];
    if (_button != 0) exitWith {false};
    private _d = if (_source isEqualType controlNull) then {ctrlParent _source} else {_source};
    _d setVariable ["ACME_stethPressed",true];
    true
};
private _up = {
    params ["_source","_button"];
    if (_button != 0) exitWith {false};
    private _d = if (_source isEqualType controlNull) then {ctrlParent _source} else {_source};
    _d setVariable ["ACME_stethPressed",false];
    true
};
_display displayAddEventHandler ["MouseButtonDown",_down];
_display displayAddEventHandler ["MouseButtonUp",_up];
// Static picture/text controls cover the panel. Receive releases over any of them too.
{
    _x ctrlAddEventHandler ["MouseButtonDown",_down];
    _x ctrlAddEventHandler ["MouseButtonUp",_up];
} forEach allControls _display;

// Independent local emitters preserve each playing clip's phase as the bell crosses the chest.
// say3D follows its emitter. Moving each emitter along the camera's vertical axis changes
// native distance attenuation continuously, without restarting samples or fading the world mixer.
private _channels = [];
for "_i" from 0 to 2 do {
    private _emitter = "#particlesource" createVehicleLocal (positionCameraToWorld [0,22,0]);
    _channels pushBack [_emitter,objNull,0];
};
_display setVariable ["ACME_stethChannels",_channels];
