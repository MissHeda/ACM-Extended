// Thin compile-once wrapper around the preserved debug renderer.
// The renderer itself is kept byte-for-byte in fn_debugMenuCore.sqf. These presentation-only substitutions keep
// the fork's large diagnostic body stable while changing only the layout/version contract requested for r5.
disableSerialization;

if (isNil {missionNamespace getVariable "ACME_debugMenu_r5Code"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";

    // Slightly smaller overall presentation. Keep the user's debug-scale preference, but trim the renderer's
    // built-in multiplier and maximum so the overlay gives more of the game view back.
    _src = _src regexReplace ["private _scale = .*?;/", "private _scale = (((_userScale max 0.50) min 1.15) * 0.68) max 0.48 min 0.78;"];

    // Always pin the overlay to the actual safe-zone left edge, including ultrawide. Width is deliberately capped
    // to a compact two-column panel instead of scaling with the full ultrawide safeZoneW, which previously let it
    // expand across most of the screen. The small floor keeps 16:9 and narrower layouts readable.
    _src = _src regexReplace ["private _gap = .*?;/", "private _gap = 0.003;"];
    _src = _src regexReplace ["private _x0 = .*?;/", "private _x0 = safeZoneX;"];
    _src = _src regexReplace ["private _w = .*?;/", "private _totalW = (safeZoneW * 0.42) min 0.455 max 0.385; private _w = ((_totalW - _gap) / 2) max 0.14;"];

    // The old title combined CfgPatches' r0 suffix with an additional debug r1 suffix, producing r0-r1.
    // r5 is the public diagnostic/release label for this build and is rendered as one atomic version string.
    _src = _src regexReplace ["ACME DEBUG v%2-%6/", "ACME DEBUG v1.2.0-r5"];

    missionNamespace setVariable ["ACME_debugMenu_r5Code", compile _src];
};

call (missionNamespace getVariable ["ACME_debugMenu_r5Code", {}]);
