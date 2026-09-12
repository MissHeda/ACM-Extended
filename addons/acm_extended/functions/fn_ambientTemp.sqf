// return the ambient air temperature in degrees c at a position, robustly, on any map, whether or not ACE weather
// is running.
// the priority order:
// 1. a mission override: missionnamespace "ACME_ambientTempC", a number. a mission maker can pin a temperature
// directly, and it is the highest priority so scenarios are deterministic.
// 2. ACE weather: ace_weather_currentTemperature, a global, or ace_weather_fnc_calculateTemperatureAtHeight,
// which is altitude-aware, if the ACE weather module is present.
// 3. a heuristic fallback: a temperate baseline adjusted for the overcast, rain, fog, time of day and altitude,
// through a lapse rate. it is tunable through the acme_ambient_* numbers below and has no ACE dependency.
// _this is optional, as [_posASL], defaulting to the position of the player.
params [["_posASL", []]];
if (_posASL isEqualTo []) then {
    _posASL = if (!isNull ACE_player) then {getPosASL ACE_player} else {getPosASL player};
};

// 1. the explicit mission override.
private _override = missionNamespace getVariable ["ACME_ambientTempC", nil];
if (!isNil "_override" && {_override isEqualType 0}) exitWith { _override };

// 2. ACE weather, if it is loaded.
if (!isNil "ace_weather_currentTemperature") exitWith { ace_weather_currentTemperature };
if (!isNil "ace_weather_fnc_calculateTemperatureAtHeight") exitWith {
    ((_posASL select 2) max 0) call ace_weather_fnc_calculateTemperatureAtHeight
};

// 3. the heuristic, with no ACE weather: a temperate baseline modulated by the conditions.
private _base    = missionNamespace getVariable ["ACME_ambient_baseC", 20];  // the clear midday sea-level baseline.
private _ovDrop  = missionNamespace getVariable ["ACME_ambient_overcastDrop", 5];  // a full overcast cools this much.
private _rainDrop= missionNamespace getVariable ["ACME_ambient_rainDrop", 4];  // full rain cools this much.
private _fogDrop = missionNamespace getVariable ["ACME_ambient_fogDrop", 2];  // full fog cools this much.
private _nightDrop = missionNamespace getVariable ["ACME_ambient_nightDrop", 8];  // the peak night cooling against midday.
private _lapse   = missionNamespace getVariable ["ACME_ambient_lapsePer1000m", 6.5];  // dry adiabatic-ish.

private _t = _base;
_t = _t - (overcast * _ovDrop);
_t = _t - (rain * _rainDrop);
_t = _t - (fog * _fogDrop);

// the diurnal curve: warmest at about 15:00 and coldest at about 05:00. the cos peaks at 15h.
private _diurnal = cos (((daytime - 15) / 24) * 360);  // +1 at 15:00 and -1 at 03:00.
_t = _t - (((1 - _diurnal) / 2) * _nightDrop);

// the altitude lapse, where the asl z is in meters.
private _alt = (_posASL select 2) max 0;
_t = _t - (_alt / 1000 * _lapse);

_t
