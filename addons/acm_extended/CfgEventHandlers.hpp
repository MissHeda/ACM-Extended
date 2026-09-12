// extended event handlers, matching the ACM and ACE convention.
// preinit registers the CBA settings and postinit starts the runtime of the addon.
class Extended_PreInit_EventHandlers {
    class ACM_Extended {
        init = "call compile preprocessFileLineNumbers '\acm_extended\XEH_preInit.sqf'";
    };
};

class Extended_PostInit_EventHandlers {
    class ACM_Extended {
        init = "call compile preprocessFileLineNumbers '\acm_extended\functions\fn_postInit.sqf'";
    };
};
