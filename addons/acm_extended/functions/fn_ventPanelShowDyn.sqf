// re-show the dynamically built screen content that fn_ventpanelhidescreen hid.
// it is needed because flipping back mid boot deliberately does not rebuild the screen, since rebuilding restarts the
// self test and replays its audio. so the controls still exist and are simply hidden, and something has to reveal
// them again. without this the self test ran to completion behind a blank panel and the ring never reappeared.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};
{
    { if (!isNull _x) then { _x ctrlShow true; }; } forEach (uiNamespace getVariable [_x, []]);
} forEach ["ACME_vent_graphBars","ACME_vent_valFields","ACME_vent_lvlWin","ACME_vent_alarmWin","ACME_vent_graphHatch"];
