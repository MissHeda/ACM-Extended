/* Named remote-execution wrapper for airway say3D calls. */
params [
    ["_source", objNull, [objNull]],
    ["_sound", "", [""]]
];
if (isNull _source || {_sound isEqualTo ""}) exitWith {};
_source say3D _sound;
