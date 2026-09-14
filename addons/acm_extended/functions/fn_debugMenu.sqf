// Compile-once wrapper for the full diagnostic renderer.
// v1.2.1 restores the original wide two-column geometry from before the compact/ultrawide passes.
// The renderer itself owns scale, position and auto-fit behavior.
disableSerialization;

if (isNil {missionNamespace getVariable "ACME_debugMenu_v121Code"}) then {
    private _src = preprocessFileLineNumbers "\acm_extended\functions\fn_debugMenuCore.sqf";
    missionNamespace setVariable ["ACME_debugMenu_v121Code", compile _src];
};

call (missionNamespace getVariable ["ACME_debugMenu_v121Code", {}]);
