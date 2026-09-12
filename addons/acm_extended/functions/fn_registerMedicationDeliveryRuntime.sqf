// B14 acknowledged medication delivery; supplier locality may differ from patient locality.
["ACME_medicationAck",{_this call ACME_fnc_medicationAck;}] call CBA_fnc_addEventHandler;
[{call ACME_fnc_medicationRetry;},1,[]] call CBA_fnc_addPerFrameHandler;
