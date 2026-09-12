// debug overlay watchdog. this registers before the rest of postinit, so a later runtime failure cannot
// kill the overlay. do not trust a stale boolean that says a pfh exists. store the handler ids and add a
// mission EachFrame fallback.
if (isNil "ACME_debug_enabled") then { ACME_debug_enabled = missionNamespace getVariable ["ACME_debug_enabled", false]; };
if (isNil "ACME_debug_registerWatchdog") then {
    ACME_debug_registerWatchdog = {
        if (!hasInterface) exitWith {};
        if (!isNil "CBA_fnc_addPerFrameHandler" && {isNil {missionNamespace getVariable "ACME_debug_pfhId"}}) then {
            missionNamespace setVariable ["ACME_debug_pfhId", [{uiNamespace setVariable ["ACME_debug_primaryHeartbeat", diag_tickTime]; if (!isNil "ACME_fnc_debugMenu") then {call ACME_fnc_debugMenu};}, 0.25, []] call CBA_fnc_addPerFrameHandler, false];
        };
        if (isNil {missionNamespace getVariable "ACME_debug_eachFrameId"}) then {
            missionNamespace setVariable ["ACME_debug_eachFrameId", addMissionEventHandler ["EachFrame", {
                private _next = uiNamespace getVariable ["ACME_debug_nextTick", 0];
                if (diag_tickTime >= _next && {(diag_tickTime - (uiNamespace getVariable ["ACME_debug_primaryHeartbeat", -1])) > 0.75}) then {
                    uiNamespace setVariable ["ACME_debug_nextTick", diag_tickTime + 0.25];
                    if (!isNil "ACME_fnc_debugMenu") then {call ACME_fnc_debugMenu};
                };
            }], false];
        };
    };
};
call ACME_debug_registerWatchdog;
