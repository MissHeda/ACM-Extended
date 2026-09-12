// hide every screen control. it is used when the device is turned round: the inlay and the substrate are hidden by
// fn_ventflip, and the readouts are separate controls and would otherwise draw straight onto the back of the
// machine. the dynamically created content is torn down through the same lists the screen router uses.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

{
    private _c = _dlg displayCtrl _x;
    if (!isNull _c) then { _c ctrlShow false; };
// 87714 is the alarm box. it carries both the small square, which is its background color, and the trigger or
// alarm letter, which is its text, so hiding the one control removes both. it belongs in this list because this
// list is the single owner of the screen teardown: fn_ventfacegate, the dark-panel branch of the tick and
// fn_ventbootstart all reach the screen through here. without it the red square and its letter kept drawing over
// the back of the machine after a flip, and over the dark bezel after a power-off.
// fn_ventpanelshowscreen decides on every screen entry whether the box comes back, because only the live screen
// has a trigger square on its inlay for the box to sit in.
} forEach [87712,87713,87714,87716,87767,87768,87720,87721,87722,87723,87724,87725,87726,87727,87730,87731,87732,87733,87734,87735,87736,87737,87738,87769,87774,87739,87759,87761,87762,87763,87764,87740,87741,87742,87743,87744,87745,87746,87747,87748,87749,87752,87753,87750,87751,87780,87781,87782,87783,87784,87785,87786,87787,87790,87791,87792,87793,87794,87795,87796,87797,87754,87755,87756,87757,87800,87801,87802,87765,87766];

// everything built at runtime: the graph columns and caps, the hatch, the value fields, the alarm and level windows,
// the self-test ring and the logbook.
{
    { if (!isNull _x) then { _x ctrlShow false; }; } forEach (uiNamespace getVariable [_x, []]);
} forEach ["ACME_vent_graphBars","ACME_vent_valFields","ACME_vent_lvlWin","ACME_vent_alarmWin","ACME_vent_graphHatch"];
