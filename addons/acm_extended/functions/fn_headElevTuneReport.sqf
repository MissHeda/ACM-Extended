private _deg   = missionNamespace getVariable ["ACME_headElev_tiltDeg", 30];
private _pivot = missionNamespace getVariable ["ACME_headElev_pivotOffset", [0, 0.55, 0]];
private _lift  = missionNamespace getVariable ["ACME_headElev_liftZ", 0.18];
private _voff  = missionNamespace getVariable ["ACME_headElev_vestPropOffset", [-0.0624309, 0.327775, -0.262297]];
private _vp    = missionNamespace getVariable ["ACME_headElev_vestPropPitch", -180];
private _vy    = missionNamespace getVariable ["ACME_headElev_vestPropYaw", -9.52483];
private _vr    = missionNamespace getVariable ["ACME_headElev_vestPropRoll", 0];
private _text = format ["TILT %1 deg | PIVOT %2 | LIFT %3 | PC OFFSET %4 | PC ROT [%5,%6,%7]", _deg, _pivot, _lift, _voff, _vp, _vy, _vr];
[_text, 12, ACE_player] call ace_common_fnc_displayTextStructured;
