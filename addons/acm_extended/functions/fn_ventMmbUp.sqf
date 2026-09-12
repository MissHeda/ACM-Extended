// the one place a middle-button release is processed. both the control-level handlers and the display-level
// fallback route here, and the frame gate makes that safe.
// the bug this fixes: select fired from both the control handler and the display fallback for one physical release.
// two activatesel calls a frame apart means enter-edit then instantly exit-edit, which a medic experiences as the
// middle click doing nothing. the down-based version never showed it, because control and display down events do
// not both fire the way up events do, so moving select to button-up for the power-off hold exposed it.
// a frame gate at a single choke point beats guessing at the event propagation of arma, which is exactly the kind of
// guess this addon has lost builds to before.
if (!hasInterface) exitWith {};

private _fr = diag_frameNo;
if ((uiNamespace getVariable ["ACME_vent_mmbUpFrame", -1]) == _fr) exitWith {};
uiNamespace setVariable ["ACME_vent_mmbUpFrame", _fr];

private _fired = uiNamespace getVariable ["ACME_vent_mmbFired", false];
uiNamespace setVariable ["ACME_vent_mmbDown", -1];
uiNamespace setVariable ["ACME_vent_mmbFired", false];
[] call ACME_fnc_ventHoldClear;

// a release that already powered the machine off is not a select.
if (!_fired) then { call ACME_fnc_ventPanelActivateSel; };
