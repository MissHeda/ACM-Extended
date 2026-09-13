// Thin compile-once wrapper around the preserved debug renderer.
// The renderer itself is kept byte-for-byte in fn_debugMenuCore.sqf. These presentation-only substitutions keep
// the fork's large diagnostic body stable while changing only the layout/version contract requested for r5.
disableSerialization;

if (isNil {missionNamespace getVariable "ACME_debugMenu_r5Code"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";

    // Keep the two-column diagnostic readable at the bottom. The previous compact pass forced long physiology
    // values to wrap and made the lower rows look clipped, so restore more width and a little more scale while
    // retaining an ultrawide cap.
    _src = _src regexReplace ["private _scale = .*?;/", "private _scale = (((_userScale max 0.50) min 1.15) * 0.72) max 0.50 min 0.82;"];

    // Pin to the safe-zone left edge, but give the two columns enough horizontal room that labels and numeric
    // values stay on their intended rows. This remains bounded on ultrawide rather than growing with the display.
    _src = _src regexReplace ["private _gap = .*?;/", "private _gap = 0.004;"];
    _src = _src regexReplace ["private _x0 = .*?;/", "private _x0 = safeZoneX;"];
    _src = _src regexReplace ["private _w = .*?;/", "private _totalW = (safeZoneW * 0.66) min 0.78 max 0.58; private _w = ((_totalW - _gap) / 2) max 0.22;"];

    // The old title combined CfgPatches' r0 suffix with an additional debug r1 suffix, producing r0-r1.
    // r5 is the public diagnostic/release label for this build and is rendered as one atomic version string.
    _src = _src regexReplace ["ACME DEBUG v%2-%6/", "ACME DEBUG v1.2.0-r5"];

    missionNamespace setVariable ["ACME_debugMenu_r5Code", compile _src];
};

call (missionNamespace getVariable ["ACME_debugMenu_r5Code", {}]);
