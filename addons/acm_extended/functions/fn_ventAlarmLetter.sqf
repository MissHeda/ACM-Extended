// the letter code for an alarm, shown in the alarm box on the top bar.
// the real device shows a letter for the active alarm rather than a count: a medic learns to read the machine is
// showing P at a glance, the way they read a rhythm. a raw number, 2, tells you how many things are wrong and not
// what any of them is, which is the least useful thing the box could say.
// the box is one glyph wide, so each code is one or two characters. where two alarms would share a letter, the
// highest-priority one keeps the plain letter and the other is disambiguated. the mapping is stable so it can be
// memorised.
// call it as [_name] call ACME_fnc_ventAlarmLetter, which returns "A", "P", "DC" and so on.
params [["_name", ""]];
switch (_name) do {
    case "APNEA":                { "A" };  // apnea
    case "CIRCUIT DISCONNECT":   { "DC" };  // disconnect
    case "HIGH AIRWAY PRESSURE": { "P" };  // pressure (high)
    case "GAS TRAPPING":         { "AP" };  // auto-peep
    case "HIGH RESP RATE":       { "hR" };  // high rate
    case "LOW RESP RATE":        { "lR" };  // low rate
    case "LOW EXHALED VOLUME":   { "VE" };  // volume, exhaled
    case "LOW MINUTE VOLUME":    { "lV" };  // low minute volume
    case "HIGH MINUTE VOLUME":   { "hV" };  // high minute volume
    case "NO SPONT. EFFORT":     { "SP" };  // no spont effort
    default { "!" };  // anything unmapped still shows something is wrong
};
