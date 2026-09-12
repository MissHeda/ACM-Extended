// click the barrel to grab or release the plunger.
// it is allowed in two phases: dragging the saline volume down to waste, with the source loaded and not yet wasted,
// or drawing a medication up on top of the locked saline base, with the base set and a med selected. otherwise the
// plunger is inert.
private _source = uiNamespace getVariable ["ACME_SK_Source", ""];
private _base   = uiNamespace getVariable ["ACME_SK_SalineBase", -1];
private _med    = uiNamespace getVariable ["ACME_SK_Med", ""];

private _phaseWaste = (_source == "Saline" && {_base < 0});
private _phaseDraw  = (_base >= 0 && {_med != ""});

if (!_phaseWaste && {!_phaseDraw}) exitWith {
    uiNamespace setVariable ["ACME_SK_Grab", false];
    private _msg = if (_source != "Saline") then {
        "Pick Saline Flush first, then drag the plunger."
    } else {
        "Press Waste to lock your saline volume, then pick a medication to draw on top."
    };
    [_msg] call ACME_fnc_syringeKitInfo;
};

uiNamespace setVariable ["ACME_SK_Grab", !(uiNamespace getVariable ["ACME_SK_Grab", false])];
if (uiNamespace getVariable ["ACME_SK_Grab", false]) then {
    [([
        "Plunger grabbed. Push down to expel saline.",
        "Plunger grabbed. Pull up to draw epi."
    ] select _phaseDraw)] call ACME_fnc_syringeKitInfo;
} else {
    [([
        "Volume set. Hit Waste to lock it as the saline base.",
        "Epi drawn. Hit Draw to finalise the Push Dose Pressor."
    ] select _phaseDraw)] call ACME_fnc_syringeKitInfo;
};
