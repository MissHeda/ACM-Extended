// tool drag for the intubation screen.
// call it as [_mx, _my, _held] call ACME_fnc_laryngoDrag, which returns [toolx, tooly, yaw, jerk].
// the instrument does not sit on the cursor. it trails behind it, heavily, the same way the fingers do in the
// chest seal minigame, and it uses the same follow maths so the two screens feel like the same pair of hands.
// on why trailing matters here: a tool locked to the cursor is weightless, and a weightless laryngoscope makes the
// whole procedure a pointing exercise. trailing gives it mass. it has to be led rather than placed, it overshoots
// if you snatch at it, and holding it still is something you actively do rather than something that happens when
// you stop moving the mouse. that is what makes a sustained hold a real input.
// the follow model, lifted from fn_chestsealtick so the feel is identical, is
// rate = base + gain * (lag / bodyheight), capped.
// the further the cursor gets ahead, the harder the tool is pulled after it, so small movements are gentle and
// large ones are still bounded. the cap is what stops a fast flick teleporting the instrument.

params ["_mx", "_my", ["_held", ""]];

private _finite = { params ["_v"]; (_v isEqualType 0) && {!(_v isEqualTo -0)} && {_v == _v} && {abs _v < 1e10} };

private _now = diag_tickTime;
private _last = uiNamespace getVariable ["ACME_LG_DragLast", -1];
private _dt = if (_last < 0) then {0} else {(_now - _last) max 0 min 0.2};
uiNamespace setVariable ["ACME_LG_DragLast", _now];

private _pt = uiNamespace getVariable ["ACME_LG_DragPt", []];
if !(_pt isEqualType [] && {count _pt >= 2}) then { _pt = [_mx, _my]; };
_pt params ["_px", "_py"];
if !([_px] call _finite) then { _px = _mx; };
if !([_py] call _finite) then { _py = _my; };

(uiNamespace getVariable ["ACME_laryngo_rect", [0,0,1,1]]) params ["_rx","_ry","_rw","_rh"];

// the trail. it is heavier than the chest seal, because a laryngoscope is a lever held at arm's length rather than
// a fingertip.
private _base = missionNamespace getVariable ["ACME_LG_DragBaseRate", 6.0];
private _gain = missionNamespace getVariable ["ACME_LG_DragGainRate", 10.0];
private _max  = missionNamespace getVariable ["ACME_LG_DragMaxRate",  18.0];

private _lagX = _mx - _px;
private _lagY = _my - _py;
private _lag  = sqrt (((_lagX * _lagX) + (_lagY * _lagY)) max 0);
private _lagN = if (_rh > 0) then { _lag / _rh } else { 0 };

private _rate = ((_base + (_gain * _lagN)) min _max) max 0;
private _step = (_rate * _dt) min 1;

private _nx = _px + (_lagX * _step);
private _ny = _py + (_lagY * _step);
if !([_nx] call _finite) then { _nx = _mx; };
if !([_ny] call _finite) then { _ny = _my; };

// magnetise at the tongue base. it is weak, only inside a small radius, and only while moving slowly. a magnet
// that reaches out and grabs you does the job for the player. this one rewards an approach that was already
// controlled and does nothing at all for someone flailing, which also stops it fighting the acceleration gate
// below.
private _vel = if (_dt > 0) then { (sqrt (((_nx-_px)^2 + (_ny-_py)^2) max 0)) / _dt } else { 0 };
private _pull = missionNamespace getVariable ["ACME_LG_MagnetPull", 0.18];
private _rad  = missionNamespace getVariable ["ACME_LG_MagnetRadius", 0.045];
private _slow = missionNamespace getVariable ["ACME_LG_MagnetMaxVel", 0.35];

private _anchor = missionNamespace getVariable ["ACME_LG_TongueBase", [0.50, 0.62]];
private _ax = _rx + _rw * (_anchor select 0);
private _ay = _ry + _rh * (_anchor select 1);
private _d = sqrt ((((_nx-_ax)^2) + ((_ny-_ay)^2)) max 0);

if (_d < _rad && {_d > 0} && {_vel < _slow}) then {
    // it falls off with distance, so it is weakest at the edge of its own radius and never snaps.
    private _k = _pull * (1 - (_d / _rad)) * (_dt * 8) min 1;
    _nx = _nx + ((_ax - _nx) * _k);
    _ny = _ny + ((_ay - _ny) * _k);
};

uiNamespace setVariable ["ACME_LG_DragPt", [_nx, _ny]];

// jerk, and the gate.
// it is jerk rather than speed. a smooth fast sweep is fine and a snatch is not. tissue tolerates a steady load and
// tears under a sudden one, so the thing being measured is the change in velocity rather than velocity
// itself.
private _pv = uiNamespace getVariable ["ACME_LG_LastVel", 0];
private _jerk = if (_dt > 0) then { (abs (_vel - _pv)) / _dt } else { 0 };
if !([_jerk] call _finite) then { _jerk = 0; };
uiNamespace setVariable ["ACME_LG_LastVel", _vel];

// it only counts while an instrument is actually in the mouth. waving the cursor around an empty screen is not an
// injury, and gating on contact is what stops the tray and the menus triggering it.
private _inMouth = (uiNamespace getVariable ["ACME_laryngo_state", "idle"]) in ["inserted", "lifting", "tubing"];

// and only while you are gripping it. swinging a laryngoscope around loose in your hand does not tear anything,
// because the damage comes from load, and there is no load unless the fist is closed on the handle and pulling.
// so the gate requires the grip key to be down, which also means the medic can move the instrument freely to look
// around without being punished for it.
private _loaded = uiNamespace getVariable ["ACME_laryngo_holding", false];

private _over = _held != "" && {_inMouth} && {_loaded}
    && {!(uiNamespace getVariable ["ACME_laryngo_bladeLocked", false])}
    && {_dt >= 0.005} && {_dt <= 0.05}
    && {_jerk > (missionNamespace getVariable ["ACME_LG_JerkLimit", 5.5])};
private _exposure = uiNamespace getVariable ["ACME_LG_JerkExposure", 0];
_exposure = if (_over) then {_exposure + _dt} else {0};
uiNamespace setVariable ["ACME_LG_JerkExposure", _exposure];
if (_exposure >= 0.12) then {
    uiNamespace setVariable ["ACME_LG_JerkExposure", 0];
    // it is instant rather than accumulated. snatching a metal blade against teeth chips them there and then, and
    // tearing pharyngeal tissue bleeds immediately. there is no gradual budget being spent here, which is the point:
    // the player is not being asked to manage a meter, they are being asked not to snatch.
    private _p = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
    if (!isNull _p) then {
        private _onTeeth = (uiNamespace getVariable ["ACME_LG_ToothContact", false]);
        if (_onTeeth) then {
            [_p] call ACME_fnc_laryngoTeeth;
        } else {
            [_p, "jerk"] call ACME_fnc_laryngoBleed;
        };
    };
    // the instrument is thrown off by the same movement that did the damage, so the player also loses the view they
    // were holding. one mistake, two costs, and both follow from the same physical event.
    uiNamespace setVariable ["ACME_laryngo_lift", 0];
    // a snatch that tears the airway ends the look. the tick reads this and abandons the attempt as trauma. it is set
    // here rather than aborting inline, so fn_laryngodrag stays a physics and damage module and the state machine
    // owns the transition out.
    uiNamespace setVariable ["ACME_laryngo_jerkTripped", true];
};

// yaw.
// the horizontal position rotates the instrument slightly, so it reads as constrained by the mouth rather than
// floating over it. it is lagged by its own follow term, because an instrument has mass and its rotation arrives
// after its movement rather than with it.
private _off = if (_rw > 0) then { ((_nx - (_rx + _rw*0.5)) / (_rw*0.5)) max -1 min 1 } else { 0 };
private _wantYaw = _off * (missionNamespace getVariable ["ACME_LG_YawMax", 7]);
private _yaw = uiNamespace getVariable ["ACME_LG_Yaw", 0];
_yaw = _yaw + ((_wantYaw - _yaw) * ((_dt * 6) min 1));
if !([_yaw] call _finite) then { _yaw = 0; };
uiNamespace setVariable ["ACME_LG_Yaw", _yaw];

[_nx, _ny, _yaw, _jerk]
