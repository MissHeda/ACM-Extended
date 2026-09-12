if ([_this,"up"] call ACME_fnc_minigameInputMouse) exitWith {true};
// releasing a mouse button lifts that hand off the chest. with neither button held there are no fingers on the body
// at all, so the rake and the feeler are deliberate, held actions rather than something that happens passively
// whenever the cursor drifts across the casualty.
// call it as [_display, _button] call ACME_fnc_chestSealMouseUp.
params ["_display", "_button"];
switch (_button) do {
    case 0: { uiNamespace setVariable ["ACME_CS_LMB", false]; };
    case 1: { uiNamespace setVariable ["ACME_CS_RMB", false]; };
};
uiNamespace setVariable ["ACME_CS_Dragging", (uiNamespace getVariable ["ACME_CS_LMB", false]) || {uiNamespace getVariable ["ACME_CS_RMB", false]}];

// letting go cancels a burp that had not finished. it is a held action on purpose: a stray click on a seal should
// not lift it, and the hold is what makes it deliberate.
// the burp is no longer a held action, so letting go of a button must NOT cancel it. it is started by the wheel
// in fn_chestSealScroll and it runs to the end on its own, peel, hold, lay back down. cancelling it here would
// leave a seal drawn half lifted on the chest of a casualty with nothing to put it back.
false
