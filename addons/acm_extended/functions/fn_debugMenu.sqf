// Compile-once wrapper for the full diagnostic renderer.
// v1.2.1/B110 keeps the larger diagnostic layout, pins it to the true absolute safe-zone left edge on ultrawide,
// and exposes a dedicated ACM state column when horizontal room exists. The renderer owns fit behavior.
disableSerialization;

if (isNil {missionNamespace getVariable "ACME_debugMenu_v121B110Code"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";
    missionNamespace setVariable ["ACME_debugMenu_v121B110Code", compile _src];
};

call (missionNamespace getVariable ["ACME_debugMenu_v121B110Code", {}]);
