// the narc box body view: flip the injection route between vascular, meaning an iv or io line, and im, meaning
// intramuscular, then rebuild the hotspots so only valid sites for the new route are shown.
private _display = findDisplay 84000;
if (isNull _display) exitWith {};
private _route = uiNamespace getVariable ["ACME_SK_Route", "vascular"];
uiNamespace setVariable ["ACME_SK_Route", (["im", "vascular"] select (_route == "im"))];
call ACME_fnc_skBuildHotspots;
