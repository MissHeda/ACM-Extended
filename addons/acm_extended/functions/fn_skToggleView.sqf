/* B60: syringe preparation and the tandem Body Map + carousel are the two user-facing pages.
   Returning from Body Map opens a fresh preparation instance so Save/administration can never leave stale
   plunger or compound state behind. */
private _display=findDisplay 84000;
if(isNull _display)exitWith{};
if !((_display getVariable["ACME_SK_Return",[]])isEqualTo[])exitWith{};
private _view=uiNamespace getVariable["ACME_SK_View","syringe"];
if(_view=="body")exitWith{
    private _size=uiNamespace getVariable["ACME_SK_CurSize",10];
    private _patient=uiNamespace getVariable["ACME_SK_Patient",objNull];
    private _bodyPart=uiNamespace getVariable["ACME_SK_BodyPart",""];
    uiNamespace setVariable["ACME_SK_CarouselExpanded",false];
    uiNamespace setVariable["ACME_SK_CarouselHover",false];
    uiNamespace setVariable["ACME_SK_CarouselZoneHover",false];
    uiNamespace setVariable["ACME_SK_TagEditMode",false];
    uiNamespace setVariable["ACME_SK_RestoreMouse",getMousePosition];
    uiNamespace setVariable["ACME_SK_OpenBodyAfterSaveId",""];
    uiNamespace setVariable["ACME_SK_PendingInjection",[]];
    uiNamespace setVariable["ACME_SK_DiscardArmedId",""];
    closeDialog 0;
    [{_this call ACME_fnc_skOpenDraw;},[_size,_patient,_bodyPart],0.05]call CBA_fnc_waitAndExecute;
};
private _store=[ACE_player]call ACME_fnc_skStoreEnsureIds;
if !(_store isEqualTo[])then{[_store]call ACME_fnc_skSelectedIndex;};
uiNamespace setVariable["ACME_SK_View","body"];
uiNamespace setVariable["ACME_SK_CarouselExpanded",false];
uiNamespace setVariable["ACME_SK_CarouselHover",false];
uiNamespace setVariable["ACME_SK_CarouselZoneHover",false];
uiNamespace setVariable["ACME_SK_TagEditMode",false];
uiNamespace setVariable["ACME_SK_CarouselCollapseAt",0];
uiNamespace setVariable["ACME_SK_SiteIdx",-1];
uiNamespace setVariable["ACME_SK_PendingInjection",[]];
uiNamespace setVariable["ACME_SK_DiscardArmedId",""];
call ACME_fnc_skSetView;
