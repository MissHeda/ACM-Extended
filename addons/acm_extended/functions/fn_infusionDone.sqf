/* Done commits UI teardown and explicitly returns to Transfuse Fluids.
   The unload handler is suppressed from issuing a second reopen. */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display) exitWith {};
private _return = _display getVariable ["ACME_SK_Return", []];
uiNamespace setVariable ["ACME_SK_suppressReturn", true];
ace_medical_gui_pendingReopen = false;
// The prepared bag now owns the mixture. The transient syringe-into-bag context must die BEFORE the display
// unload/reopen sequence or a fast page change can inherit it and force a normal Narc Box back into infusion view.
ACME_infusion_pendingContext = nil;
missionNamespace setVariable ["ACME_infusion_bagTally", []];
_display closeDisplay 2;
if !(_return isEqualTo []) then {
    [{[_this] call ACME_fnc_reopenTransfusion;}, _return, 0.05] call CBA_fnc_waitAndExecute;
};
