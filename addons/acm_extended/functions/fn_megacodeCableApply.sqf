// apply one cable-tuner slider change to the cable of the megacode laptop, live. the helper offsets re-seat the
// attach points of the rope, because the rope follows its anchors. the laptop x, y and z move the laptop in its
// heading frame. the wire-end pitch, yaw and roll re-orient the laptop-side rope anchor. the slack and the
// segments re-create the rope.
// the cable objects were spawned on the server, so the actual work runs there, re-invoked through remoteexec from
// a client. the updated values persist as globals, so new megacode spawns use the tuned cable.
// _this is [_key, _val], from a slider, or [_key, _val, _laptop], for the server re-invoke.
params ["_key", "_val", ["_laptop", objNull]];
if (isNull _laptop) then { _laptop = uiNamespace getVariable ["ACME_MC_CableLaptop", objNull]; };
if (isNull _laptop) exitWith {};
if (!isServer) exitWith { [_key, _val, _laptop] remoteExec ["ACME_fnc_megacodeCableApply", 2]; };

private _dummy = _laptop getVariable ["ACME_megacodeDummy", objNull];
private _lOff  = +(missionNamespace getVariable ["ACME_megacode_laptopHoseOffset", [0,-0.13,0.035]]);
private _dOff  = +(missionNamespace getVariable ["ACME_megacode_dummyHoseOffset", [0,0.32,0.12]]);
private _slack = missionNamespace getVariable ["ACME_megacode_ropeSlack", 0.2];
private _seg   = missionNamespace getVariable ["ACME_megacode_ropeSegments", 0];
private _pos   = +(missionNamespace getVariable ["ACME_megacode_laptopPosOffset", [0,0,0]]);  // the laptop position, in the heading frame.
private _rPit  = missionNamespace getVariable ["ACME_megacode_ropeEndPitch", -35];  // the wire-end orientation at the laptop.
private _rYaw  = missionNamespace getVariable ["ACME_megacode_ropeEndYaw", 0];
private _rRol  = missionNamespace getVariable ["ACME_megacode_ropeEndRoll", 0];
private _stub  = missionNamespace getVariable ["ACME_megacode_ropeEndStub", 0.12];  // the wire-end anchor offset length.
// the legacy laptop pitch, yaw and roll. it is no longer exposed in the tuner, having been replaced by the laptop
// x, y and z, and it is kept callable.
private _pitch = missionNamespace getVariable ["ACME_megacode_laptopPitch", 0];
private _yaw   = missionNamespace getVariable ["ACME_megacode_laptopYaw", 0];
private _roll  = missionNamespace getVariable ["ACME_megacode_laptopRoll", 0];

private _helpers = if (isNull _dummy) then {[]} else {_dummy getVariable ["ACME_MC_helpers", []]};
_helpers params [["_dHelper", objNull], ["_lHelper", objNull]];

// the local-frame anchor offset for the laptop end of the wire. a physics rope cannot have its end orientation
// set, so the pitch and yaw rotate this small offset, the laptop anchor of the wire, to aim the wire instead of
// letting it stick straight up. the base is local +y, forward, the yaw swings horizontally and the pitch tilts
// toward vertical.
private _fnc_stubVec = {
    private _p = _rPit * (pi / 180);
    private _y = _rYaw * (pi / 180);
    [_stub * (cos _p) * (sin _y), _stub * (cos _p) * (cos _y), _stub * (sin _p)]
};

private _fnc_rebuildRope = {
    if (!isNull _lHelper && {!isNull _dHelper} && {!isNull _dummy}) then {
        private _oldRope = _dummy getVariable ["ACME_MC_rope", ropeNull];
        if (!isNull _oldRope) then { ropeDestroy _oldRope; };
        private _len = ((_laptop distance _dummy) + _slack) max 0.5;
        private _sv = call _fnc_stubVec;
        // biki ropecreate is [from, frompos, to, topos, length, ropestart, ropeend, ropetype, nsegments].
        // the segment count is the 9th argument, a number with an engine maximum of 63, and not the 6th. ropestart and
        // ropeend stay [].
        // the laptop end anchors at _sv, the steerable wire-end offset, rather than at the helper origin.
        private _rope = if (_seg >= 1) then {
            ropeCreate [_lHelper, _sv, _dHelper, [0,0,0], _len, [], [], "ace_refuel_fuelHose", (round _seg) min 63]
        } else {
            ropeCreate [_lHelper, _sv, _dHelper, [0,0,0], _len, [], [], "ace_refuel_fuelHose"]
        };
        if (isNull _rope) then { _rope = ropeCreate [_lHelper, _sv, _dHelper, [0,0,0], _len] };
        _dummy setVariable ["ACME_MC_rope", _rope, false];
    };
};

// the wire-end pitch, yaw and roll: simply re-form the hose so it re-anchors at the new steering offset.
private _fnc_applyRopeEnd = { call _fnc_rebuildRope; };

switch (_key) do {
    // where the wire plugs into the laptop, which is the anchor point on the laptop.
    case "lx": { _lOff set [0, _val]; if (!isNull _lHelper) then { detach _lHelper; _lHelper attachTo [_laptop, _lOff]; }; };
    case "ly": { _lOff set [1, _val]; if (!isNull _lHelper) then { detach _lHelper; _lHelper attachTo [_laptop, _lOff]; }; };
    case "lz": { _lOff set [2, _val]; if (!isNull _lHelper) then { detach _lHelper; _lHelper attachTo [_laptop, _lOff]; }; };
    // where the wire attaches on the patient.
    case "dy": { _dOff set [1, _val]; if (!isNull _dHelper) then { detach _dHelper; _dHelper attachTo [_dummy, _dOff]; }; };
    case "dz": { _dOff set [2, _val]; if (!isNull _dHelper) then { detach _dHelper; _dHelper attachTo [_dummy, _dOff]; }; };
    // the laptop position in its heading frame, which replaces the old laptop pitch, yaw and roll. the helper follows,
    // and the rope is re-lengthed.
    case "mlx": { _pos set [0, _val]; [_laptop, _pos select 0, _pos select 1, _pos select 2] call ACME_fnc_megacodeLaptopMove; call _fnc_rebuildRope; };
    case "mly": { _pos set [1, _val]; [_laptop, _pos select 0, _pos select 1, _pos select 2] call ACME_fnc_megacodeLaptopMove; call _fnc_rebuildRope; };
    case "mlz": { _pos set [2, _val]; [_laptop, _pos select 0, _pos select 1, _pos select 2] call ACME_fnc_megacodeLaptopMove; call _fnc_rebuildRope; };
    // the wire-end orientation at the laptop: orient the laptop-side anchor, then re-form the hose.
    case "rpitch": { _rPit = _val; call _fnc_applyRopeEnd; };
    case "ryaw":   { _rYaw = _val; call _fnc_applyRopeEnd; };
    case "rroll":  { _rRol = _val; call _fnc_applyRopeEnd; };
    case "stub":   { _stub = _val; call _fnc_applyRopeEnd; };
    // the legacy laptop orientation, which is no longer exposed in the tuner.
    case "pitch": { _pitch = _val; [_laptop, _pitch, _yaw, _roll] call ACME_fnc_megacodeLaptopOrient; };
    case "yaw":   { _yaw   = _val; [_laptop, _pitch, _yaw, _roll] call ACME_fnc_megacodeLaptopOrient; };
    case "roll":  { _roll  = _val; [_laptop, _pitch, _yaw, _roll] call ACME_fnc_megacodeLaptopOrient; };
    case "slack": { _slack = _val; call _fnc_rebuildRope; };
    case "seg":   { _seg   = _val; call _fnc_rebuildRope; };
};

// persist, so future megacode spawns use the tuned cable, laptop position and wire-end orientation.
missionNamespace setVariable ["ACME_megacode_laptopHoseOffset", _lOff, true];
missionNamespace setVariable ["ACME_megacode_dummyHoseOffset", _dOff, true];
missionNamespace setVariable ["ACME_megacode_ropeSlack", _slack, true];
missionNamespace setVariable ["ACME_megacode_ropeSegments", _seg, true];
missionNamespace setVariable ["ACME_megacode_laptopPosOffset", _pos, true];
missionNamespace setVariable ["ACME_megacode_ropeEndPitch", _rPit, true];
missionNamespace setVariable ["ACME_megacode_ropeEndYaw", _rYaw, true];
missionNamespace setVariable ["ACME_megacode_ropeEndRoll", _rRol, true];
missionNamespace setVariable ["ACME_megacode_ropeEndStub", _stub, true];
missionNamespace setVariable ["ACME_megacode_laptopPitch", _pitch, true];
missionNamespace setVariable ["ACME_megacode_laptopYaw", _yaw, true];
missionNamespace setVariable ["ACME_megacode_laptopRoll", _roll, true];
