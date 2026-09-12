// B59 syringe-menu lifetime: prepared/tagged syringe records and selection IDs are personal kit state for the current life only.
if (hasInterface) then {
    player addEventHandler ["Killed", {params ["_unit"]; [_unit, []] call ACME_fnc_narcStoreCommit; uiNamespace setVariable ["ACME_SK_SelectedSyringeId", ""]; uiNamespace setVariable ["ACME_SK_CarouselIdx", -1]; uiNamespace setVariable ["ACME_SK_SelDrawn", -1];}];
    player addEventHandler ["Respawn", {params ["_unit"]; [_unit, []] call ACME_fnc_narcStoreCommit; uiNamespace setVariable ["ACME_SK_SelectedSyringeId", ""]; uiNamespace setVariable ["ACME_SK_CarouselIdx", -1]; uiNamespace setVariable ["ACME_SK_SelDrawn", -1]; uiNamespace setVariable ["ACME_SK_SiteIdx", -1];}];
};
