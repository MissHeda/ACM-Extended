/* Done commits UI teardown and explicitly returns to Transfuse Fluids.
   The unload handler is suppressed from issuing a second reopen. */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display) exitWith {};
private _return = _display getVariable ["ACME_SK_Return", []];
uiNamespace setVariable ["ACME_SK_suppressReturn", true];
ace_medical_gui_pendingReopen = false;
_display closeDisplay 2;
if !(_return isEqualTo []) then {
    [{[_this] call ACME_fnc_reopenTransfusion;}, _return, 0.05] call CBA_fnc_waitAndExecute;
};
