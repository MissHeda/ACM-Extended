/* Server-owned deletion wrapper for networked ACME helper objects. */
params [["_object", objNull, [objNull]]];
if (!isServer || {isNull _object}) exitWith {};
deleteVehicle _object;
