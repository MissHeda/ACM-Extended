/* Called in the owner's unscheduled dispatcher. Keep the exact native event
   contract/listeners, then verify only this puncture's site within the same call. */
params ["_medic", "_patient", "_bodyPart", "_type", "_site", "_epoch"];
if (isNull _patient || {!local _patient}
    || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {};
if !(_bodyPart in ["head","body","leftarm","rightarm","leftleg","rightleg"]
    && {_site in [0,1,2]} && {_type in [1,2,5,6]}) exitWith {};
["ACM_circulation_setIVLocal", [_medic, _patient, _bodyPart, _type, true, _site]] call CBA_fnc_localEvent;
[_patient, _bodyPart, _site, _type, [], _epoch] call ACME_fnc_ivEnforceSite;
