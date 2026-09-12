// Recoverable reset after a real interruption or sustained traumatic input.
// Miss/trauma accounting is owner-routed; neither resets nor errors permanently prohibit a tube.
disableSerialization;
params [["_reason", "unknown"]];
if (uiNamespace getVariable ["ACME_laryngo_done", false]) exitWith {};
uiNamespace setVariable ["ACME_laryngo_done", true];

private _p = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (!isNull _p) then { [_p, _reason] call ACME_fnc_laryngoFail; };

private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (!isNull _dlg) then { (_dlg displayCtrl 87810) ctrlSetText "That attempt is done. Reseat and try again, or Done to back out."; };

// stay in the screen. a failed attempt used to close the dialog out from under the medic, which meant reopening it
// every time anything went wrong. the consequences have already been applied to the patient, and the screen
// simply resets to the start so the next attempt can begin immediately. leaving is done with the done button.
[{
    params ["_oldDisplay", "_oldPatient"];
    if (isNull _oldDisplay || {_oldDisplay != (uiNamespace getVariable ["ACME_laryngo_dlg", displayNull])}
        || {_oldPatient != (uiNamespace getVariable ["ACME_laryngo_patient", objNull])}) exitWith {};
    uiNamespace setVariable ["ACME_laryngo_done", false];
    // the tool stays in your hand. putting it away for you was never wanted.
    uiNamespace setVariable ["ACME_laryngo_state",
        (if ((uiNamespace getVariable ["ACME_laryngo_held", ""]) == "scope") then {"scopeHeld"} else {"idle"})];
    uiNamespace setVariable ["ACME_laryngo_holding", false];
    uiNamespace setVariable ["ACME_laryngo_regripHeld", false];
    uiNamespace setVariable ["ACME_laryngo_gripStr", 0];
    uiNamespace setVariable ["ACME_laryngo_airwayOpen", false];
    uiNamespace setVariable ["ACME_laryngo_lift", 0];
    uiNamespace setVariable ["ACME_laryngo_liftPending", 0];
    uiNamespace setVariable ["ACME_laryngo_overPressure", 0];
    uiNamespace setVariable ["ACME_laryngo_reveal", 0];
    uiNamespace setVariable ["ACME_laryngo_pryPressure", 0];
    uiNamespace setVariable ["ACME_laryngo_pryReveal", 0];
    uiNamespace setVariable ["ACME_laryngo_tubeDepth", 0];
    uiNamespace setVariable ["ACME_laryngo_tubeAim", ""];
    uiNamespace setVariable ["ACME_laryngo_tubeCatch", -1];
    uiNamespace setVariable ["ACME_laryngo_tubeRammed", false];
    uiNamespace setVariable ["ACME_laryngo_tubePassed", false];
    // the tube comes out.
    // the reset cleared the depth and left the tube in the hand, so it stayed drawn on screen at depth zero. that
    // was survivable until the blade became required to move a tube: after a failure the blade is out, so the tube
    // could not be moved at all and simply sat there.
    // a failed attempt ends with the tube out of the airway and back in the tray, which is what happens in life.
    // it is not consumed, so it can be picked up and used again.
    // the scope is left alone. if it was in the hand it stays there, because the medic has not put it down.
    if ((uiNamespace getVariable ["ACME_laryngo_held", ""]) == "tube") then {
        uiNamespace setVariable ["ACME_laryngo_held", ""];
    };
    uiNamespace setVariable ["ACME_laryngo_tubeInHand", false];
    uiNamespace setVariable ["ACME_laryngo_tubeGrip", false];
    uiNamespace setVariable ["ACME_laryngo_tubeImpulse", 0];
    uiNamespace setVariable ["ACME_laryngo_tubeStep", 0];
    call ACME_fnc_laryngoRefreshSlots;
    uiNamespace setVariable ["ACME_laryngo_jamTime", 0];
    uiNamespace setVariable ["ACME_laryngo_bladeYaw", 0];
    uiNamespace setVariable ["ACME_laryngo_attemptStarted", false];
    uiNamespace setVariable ["ACME_laryngo_attemptClock", 0];
    [] call ACME_fnc_laryngoRefreshSlots;
}, [_dlg, _p], 0.7] call CBA_fnc_waitAndExecute;
