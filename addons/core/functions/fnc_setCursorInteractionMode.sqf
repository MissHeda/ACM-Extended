#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Core-owned ACE interact-menu integration boundary for the temporary cursor-mode override used by procedure
 * flashlight access. Callers are responsible for preserving/restoring the player's prior setting values.
 */
params [
    ["_selfInteraction", false, [true]],
    ["_worldInteraction", false, [true]]
];
missionNamespace setVariable ["ace_interact_menu_alwaysUseCursorSelfInteraction", _selfInteraction];
missionNamespace setVariable ["ace_interact_menu_alwaysUseCursorInteraction", _worldInteraction];
true
