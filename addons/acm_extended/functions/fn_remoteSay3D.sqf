/* Named remote-execution wrapper for say3D.
   Keeps ACME audio compatible with strict CfgRemoteExec command whitelists. */
params [
    ["_source", objNull, [objNull]],
    ["_sound", "", [""]]
];
if (isNull _source || {_sound isEqualTo ""}) exitWith {};
_source say3D _sound;
