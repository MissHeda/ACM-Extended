/* Use the same configured Arma button sound as other Narc Box buttons; local UI only. */
private _sound = getArray (configFile >> "RscButton" >> "soundClick");
if (count _sound >= 3 && {(_sound select 0) != ""}) then {playSoundUI [_sound select 0, _sound select 1, _sound select 2];};
