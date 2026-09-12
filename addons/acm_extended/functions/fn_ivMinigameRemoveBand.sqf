// take the constricting band off. it returns it to the box and resets the wipe state, because the band makes the
// vein palpable.
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg) exitWith {};
uiNamespace setVariable ["ACME_IV_BandOn", false];
// Removing the band is its own right-click action. Stop any active left hold,
// while leaving the selected needle/pad/tubing and insertion progress intact.
uiNamespace setVariable ["ACME_IV_Dragging", false];
uiNamespace setVariable ["ACME_IV_Cleaned", false];
uiNamespace setVariable ["ACME_IV_WipeSwipes", 0];
// the scrub trail is NOT wiped here any more. antiseptic on skin does not vanish because you put the pad down
// or took the band off; it dries and fades. picking the pad up again should let you keep working the same
// area, and it did not, because this deleted everything first.
// only the stroke anchor resets, so the next dab starts a fresh stroke rather than drawing a line back from
// wherever the cursor was last time.
uiNamespace setVariable ["ACME_IV_PrepLast", []];
(_dlg displayCtrl 86502) ctrlShow false;
(_dlg displayCtrl 86505) ctrlShow false;
(_dlg displayCtrl 86506) ctrlShow false;
(_dlg displayCtrl 86507) ctrlShow false;
private _stain = uiNamespace getVariable ["ACME_IV_CleanCtrl", controlNull];
if (!isNull _stain) then { ctrlDelete _stain; uiNamespace setVariable ["ACME_IV_CleanCtrl", controlNull]; };
[] call ACME_fnc_ivMinigameRefreshBandSlot;
[false] call ACME_fnc_ivMinigameBandFlag;  // the limb is free, so any line in it can run.

// the band came off, so the saved state for this limb has to follow.
[] call ACME_fnc_ivMinigameSaveState;
