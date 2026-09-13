// Thin compile-once wrapper around the preserved debug renderer.
// The renderer itself is kept byte-for-byte in fn_debugMenuCore.sqf. These presentation-only substitutions keep
// the fork's large diagnostic body stable while changing only the layout/version contract requested for r5.
disableSerialization;

if (isNil {missionNamespace getVariable "ACME_debugMenu_r5Code"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";

    // Slightly smaller overall presentation. Keep the user's debug-scale preference, but trim the renderer's
    // built-in multiplier and maximum so the overlay gives more of the game view back.
    _src = _src regexReplace ["private _scale = .*?;/", "private _scale = (((_userScale max 0.50) min 1.15) * 0.64) max 0.46 min 0.74;"];

    // Anchor to the real safe-zone left edge, not the centered 16:9 canvas. On ultrawide this consumes the left
    // gutter instead of floating inward. The total two-column width is also reduced by ten percent.
    _src = _src regexReplace ["private _gap = .*?;/", "private _gap = 0.0035;"];
    _src = _src regexReplace ["private _x0 = .*?;/", "private _x0 = safeZoneX;"];
    _src = _src regexReplace ["private _w = .*?;/", "private _totalW = (_uiW * 0.90) min safeZoneW; private _w = ((_totalW - _gap) / 2) max 0.10;"];

    // The old title combined CfgPatches' r0 suffix with an additional debug r1 suffix, producing r0-r1.
    // r5 is the public diagnostic/release label for this build and is rendered as one atomic version string.
    _src = _src regexReplace ["ACME DEBUG v%2-%6/", "ACME DEBUG v1.2.0-r5"];

    missionNamespace setVariable ["ACME_debugMenu_r5Code", compile _src];
};

call (missionNamespace getVariable ["ACME_debugMenu_r5Code", {}]);
