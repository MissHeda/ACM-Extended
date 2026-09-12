// restore the own ACE cursor-menu settings of the player after we forced them.
// while a display-mode minigame is open we force ace_interact_menu_alwaysUseCursorSelfInteraction, and its world
// twin, to true, because that is the variable that decides whether ACE builds the cursormenu display. it is the
// same machine it builds on the map: display 91919 on top, its own mouse capture, its own key re-injection and
// icons rendered on itself. without it, ACE takes the camera-aim branch, which is structurally incompatible with
// a panel that owns the mouse.
// these are the settings of the player, so they must come back exactly as found. the restoration is triggered from
// the ace_interactMenuClosed event, which ACE raises at the end of every keyup so it cannot be missed, and from
// minigameclose, belt and braces. the isnil guard makes it idempotent, so restoring twice is a no-op.
if (isNil "ACME_ace_cursorSaved") exitWith {};

ACME_ace_cursorSaved params [["_self", false], ["_world", false]];
[_self, _world] call ACM_core_fnc_setCursorInteractionMode;
ACME_ace_cursorSaved = nil;
