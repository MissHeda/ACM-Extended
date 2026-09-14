ACME_infusion_version = getText (configFile >> "CfgPatches" >> "ACM_Extended" >> "version");
if (ACME_infusion_version == "") then { ACME_infusion_version = "1.2.1"; };
ACME_buildBatch = "B126";
ACME_debugRevision = "r1";
ACME_networkAuditRevision = "NA2-live-collaboration-source-candidate";
call ACME_fnc_chestSealNetInit;
[] call ACME_fnc_ventCustodyInit;
[{ call ACME_fnc_ownerInit; }, []] call CBA_fnc_execNextFrame;
