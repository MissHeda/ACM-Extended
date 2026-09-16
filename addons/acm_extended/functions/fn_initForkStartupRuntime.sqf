ACME_infusion_version = getText (configFile >> "CfgPatches" >> "ACM_Extended" >> "version");
if (ACME_infusion_version == "") then { ACME_infusion_version = "1.2.1"; };
ACME_buildBatch = "B116";
ACME_debugRevision = "r1";
ACME_networkAuditRevision = "NA2-live-collaboration-source-candidate";
call ACME_fnc_chestSealNetInit;
[] call ACME_fnc_ventCustodyInit;
[{ call ACME_fnc_ownerInit; }, []] call CBA_fnc_execNextFrame;

// Cumulative clinical-expansion bootstrap. Kept on this executed startup path because
// ACM Extended's current config.cpp inlines its XEH declarations; the legacy standalone
// CfgEventHandlers.hpp is not the authoritative registration surface.
call compile preprocessFileLineNumbers "\acm_extended\functions\fn_expansionBootstrap.sqf";
