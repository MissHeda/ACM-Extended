// the map sea-level datum.
// the problem: altitude physiology, meaning hypoxia, trapped-gas expansion and cabin chill, is driven by getPosASL,
// which reports height above the zero of the engine rather than above the intended sea level of the map. most
// terrains put their ocean at zero and the two agree. some do not: a terrain authored with its base plate at, say,
// 6000 m reports every casualty standing on flat ground as being at 6000 m. with ACME_altitude_minMetres at 500,
// that means a casualty lying in the dirt is treated as being at altitude, so SpO2 falls, a pneumothorax expands,
// and the medic is chasing a hypoxia that only exists because of a mapping decision. this resolves the offset, so
// asl can be corrected.
// how it decides: there is no engine call for what a terrain intended as sea level, so the lowest point on the map
// is used as the datum. that is the best available proxy.
// a terrain with an ocean has seabed below zero, so the minimum is negative and no correction is applied.
// a terrain whose base plate sits at 6000 m has a minimum near 6000 m, which is exactly the offset to remove.
// a threshold guards it, because a genuinely high-altitude map, an altiplano or a himalayan valley floor, is a
// legitimate design choice and its hypoxia should be modeled. only a minimum above the threshold is treated as an
// authoring offset rather than as real elevation.
// the override is ACME_altitude_datumMode.
// -1 is auto-detect, the default, which is the behavior above.
// 0 is no correction at all, using the raw asl. set this on a map that really is at altitude and where you want
// the physiology to reflect that.
// a value above 0 is an explicit datum in meters, for a map where the auto-detection guesses wrong.
// it is resolved once and cached, because the terrain cannot change mid-mission. it is resolved lazily on the first
// altitude tick rather than at postinit, so a mission that never flies never pays the sampling cost.
// it returns the meters to subtract from getPosASL to get the true altitude above the intended sea level of the
// map.

if (!isNil "ACME_altitude_datum") exitWith { ACME_altitude_datum };

private _mode = missionNamespace getVariable ["ACME_altitude_datumMode", -1];

if (_mode >= 0) exitWith {
    ACME_altitude_datum = _mode;
    ACME_altitude_datum
};

// a coarse grid sample. the step is scaled to the terrain, so a 4 km map and a 40 km map cost the same: 64 by 64 is
// 4096 getTerrainHeightASL calls, which is trivial as a one-off and far cheaper than sampling a fixed step.
private _ws = worldSize;
if (_ws <= 0) exitWith {
    ACME_altitude_datum = 0;
    ACME_altitude_datum
};
private _step = (_ws / 64) max 50;
private _min = 1e9;
private _x = 0;
while {_x <= _ws} do {
    private _y = 0;
    while {_y <= _ws} do {
        private _h = getTerrainHeightASL [_x, _y];
        if (_h < _min) then { _min = _h };
        _y = _y + _step;
    };
    _x = _x + _step;
};

private _thresh = missionNamespace getVariable ["ACME_altitude_datumThreshold", 3000];
ACME_altitude_datum = if (_min > _thresh) then { floor _min } else { 0 };


ACME_altitude_datum
