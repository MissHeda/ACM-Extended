// Late-loaded inventory text corrections owned by ACM Extended.
// Requiring ACM_Extended guarantees the base item classes already exist before these display-only patches apply.
class CfgPatches {
    class ACM_itemtext {
        name = "ACM Extended Item Text";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"ACM_Extended"};
        author = "mavis";
    };
};

class CfgWeapons {
    // Display-only patch. The item remains ACM_HPMK with all inventory, mass, medical and runtime behavior intact.
    class ACM_HPMK {
        descriptionShort = "Hypothermia Management & Prevention Kit";
    };
};
