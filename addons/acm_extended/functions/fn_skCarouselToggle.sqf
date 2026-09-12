/* B60: the Syringe Menu button expands/collapses the tandem carousel instead of switching to a separate page. */
private _d=findDisplay 84000;if(isNull _d)exitWith{};
private _store=[ACE_player]call ACME_fnc_skStoreEnsureIds;
if(_store isEqualTo [])exitWith{};
private _view=uiNamespace getVariable["ACME_SK_View","syringe"];
if(_view!="body")then{
    [_store]call ACME_fnc_skSelectedIndex;
    uiNamespace setVariable["ACME_SK_View","body"];
    uiNamespace setVariable["ACME_SK_CarouselExpanded",true];
    uiNamespace setVariable["ACME_SK_CarouselCollapseAt",diag_tickTime+0.90];
    call ACME_fnc_skSetView;
}else{
    private _next=!(uiNamespace getVariable["ACME_SK_CarouselExpanded",false]);
    uiNamespace setVariable["ACME_SK_CarouselExpanded",_next];
    uiNamespace setVariable["ACME_SK_CarouselHover",false];
    uiNamespace setVariable["ACME_SK_CarouselCollapseAt",if(_next)then{diag_tickTime+0.90}else{0}];
    [0.12]call ACME_fnc_skDynamicLayout;
    [0.12]call ACME_fnc_skCarouselRender;
    call ACME_fnc_skBuildHotspots;
    call ACME_fnc_skSetView;
};
