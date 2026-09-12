// place a game blood decal on the ground near the patient while a chest tube passively drains. the decal size scales
// with the remaining pleural fluid.
// decals never overlap, because their footprints are kept apart, since the textures glitch when they intersect: a
// candidate spot is rejected if it is within r1 plus r2 plus the gap of any existing decal, so at most one sits per
// patch of ground, one per chest side, with more spreading out around the body. it is a local visual.
params ["_patient"];
if (isNull _patient) exitWith {};
private _fluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];
private _cr = switch (true) do {
    case (_fluid >= 0.6): { ["BloodPool_01_Large_New_F", 1.5] };
    case (_fluid >= 0.3): { ["BloodPool_01_Medium_New_F", 1.0] };
    default { ["BloodSplatter_01_Small_New_F", 0.55] };
};
_cr params ["_cls", "_rad"];

private _decals = (_patient getVariable ["ACME_thora_bloodDecals", []]) select { !isNull (_x select 0) };
if ((count _decals) >= (missionNamespace getVariable ["ACME_thora_maxBloodDecals", 16])) exitWith {
    _patient setVariable ["ACME_thora_bloodDecals", _decals];
};
private _gap = missionNamespace getVariable ["ACME_thora_bloodGap", 0.2];

private _placed = false;
for "_try" from 1 to 12 do {
    if (!_placed) then {
        private _wp = _patient modelToWorldVisual [((random 0.8) - 0.4), ((random 0.9) - 0.1), 0];
        private _px = _wp select 0;
        private _py = _wp select 1;
        private _ok = true;
        {
            _x params ["_o", "_orad"];
            private _op = getPosATLVisual _o;
            if ((sqrt (((_px - (_op select 0)) ^ 2) + ((_py - (_op select 1)) ^ 2))) < (_rad + _orad + _gap)) exitWith { _ok = false; };
        } forEach _decals;
        if (_ok) then {
            private _d = createVehicleLocal [_cls, [_px, _py, 0], [], 0, "CAN_COLLIDE"];
            _d setPosATL [_px, _py, 0];
            _d setDir (random 360);
            _d enableSimulation false;
            _decals pushBack [_d, _rad];
            _placed = true;
        };
    };
};
_patient setVariable ["ACME_thora_bloodDecals", _decals];
