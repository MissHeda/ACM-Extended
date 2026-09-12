// close a minigame, whichever way it was opened.
// call it as [86600] call ACME_fnc_minigameClose.
// closedialog 0 only closes dialogs. if the panel was opened as a display, see fn_minigameopen, closedialog does
// nothing at all and the panel becomes unclosable, which is exactly the sort of thing that ends a session. so every
// close path has to go through here, and here has to handle both.
params [["_idd", -1]];
if (!hasInterface) exitWith {};

private _d = findDisplay _idd;
if (!isNull _d) then {
    _d closeDisplay 1;  // works for a display; harmless on a dialog
};

// a dialog opened with createdialog is also closed by closedialog. doing both is safe: whichever one applies wins
// and the other is a no-op. being certain the panel closes matters far more than being elegant about it.
if (dialog) then {
    closeDialog 0;
};

// belt and braces: if the panel dies while the forced cursor setting is live, from esc mid-menu, a script error or
// anything else, give the player their settings back here too. it is idempotent, so a double restore costs
// nothing.
[] call ACME_fnc_aceCursorRestore;
