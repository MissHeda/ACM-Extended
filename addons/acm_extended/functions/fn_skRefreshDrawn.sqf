/* B60: the Drawn list is retired. Reconcile stable selection and repaint the tandem carousel when Body Map is open. */
private _display=findDisplay 84000;
private _store=[ACE_player]call ACME_fnc_skStoreEnsureIds;
if(_store isEqualTo[])then{
    uiNamespace setVariable["ACME_SK_SelectedSyringeId",""];
    uiNamespace setVariable["ACME_SK_SelDrawn",-1];
    uiNamespace setVariable["ACME_SK_CarouselIdx",-1];
}else{
    [_store]call ACME_fnc_skSelectedIndex;
};
if(isNull _display)exitWith{};
if((uiNamespace getVariable["ACME_SK_View","syringe"])=="body")then{call ACME_fnc_skCarouselRender;};
