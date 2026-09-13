/* B68: Body Map syringe administration animation.
   Clicking a valid IV/IO or IM site promotes the carousel, locks selection, and drives the selected syringe
   plunger toward its post-dose position over exactly 3 seconds while syringe_push.ogg plays.  Medication is only
   committed after the visual push completes, so an invalidated access/patient never consumes the syringe. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body"}) exitWith {false};
if (uiNamespace getVariable ["ACME_SK_InjectionBusy",false]) exitWith {false};
if (uiNamespace getVariable ["ACME_SK_TagEditMode",false]) exitWith {false};

private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
if (!(_pending isEqualType []) || {count _pending < 3}) exitWith {false};
_pending params ["_bodyPart","_siteIdx","_route"];
uiNamespace setVariable ["ACME_SK_SiteIdx",_siteIdx];
uiNamespace setVariable ["ACME_SK_Route",_route];
private _patient = uiNamespace getVariable ["ACME_SK_Patient",objNull];
if (isNull _patient) then {_patient = _d getVariable ["ACME_SK_ReturnPatient",objNull];};
if (isNull _patient) exitWith {uiNamespace setVariable ["ACME_SK_PendingInjection",[]]; call ACME_fnc_skBodyActionRender; false};
private _iv = _route != "im";
private _present = true;
if (_iv) then {_present = if (_siteIdx >= 0) then {[_patient,_bodyPart,0,_siteIdx] call ACM_circulation_fnc_hasIV} else {[_patient,_bodyPart,0] call ACM_circulation_fnc_hasIO};};
if (!_present) exitWith {uiNamespace setVariable ["ACME_SK_PendingInjection",[]]; call ACME_fnc_skBodyActionRender; false};

private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store] call ACME_fnc_skSelectedIndex;
if (_idx < 0 || {_idx >= count _store}) exitWith {
    uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
    call ACME_fnc_skBodyActionRender;
    false
};
private _entry = +(_store select _idx);
private _stableId = _entry param [11,"",[""]];
if (_stableId == "") exitWith {
    uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
    call ACME_fnc_skBodyActionRender;
    false
};
_entry params ["_med",["_size",10],["_amt",0],["_label",""],["_nsMl",0]];
private _total = (_amt + _nsMl) max 0;
if (_total <= 0) exitWith {
    uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
    call ACME_fnc_skBodyActionRender;
    false
};

// Push-dose epinephrine can intentionally leave solution behind. Every other prepared syringe empties to zero.
private _remainingFrac = 0;
if ((_entry param [6,""]) == "epiMixB12") then {
    private _choice = uiNamespace getVariable ["ACME_SK_EpiDoseChoice",0];
    private _pushMl = ([1,2,_total] select (((_choice max 0) min 2))) min _total;
    _remainingFrac = ((((_total - _pushMl) max 0) / (_size max 0.01)) max 0) min 1;
};

uiNamespace setVariable ["ACME_SK_InjectionBusy",true];
uiNamespace setVariable ["ACME_SK_CarouselBusy",true];
uiNamespace setVariable ["ACME_SK_CarouselExpanded",true];
uiNamespace setVariable ["ACME_SK_CarouselHover",false];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
_d setVariable ["ACME_SK_InjectionStableId",_stableId];
_d setVariable ["ACME_SK_InjectionBodyPart",_bodyPart];
_d setVariable ["ACME_SK_InjectionSiteIdx",_siteIdx];
_d setVariable ["ACME_SK_InjectionRoute",_route];

[0.12] call ACME_fnc_skDynamicLayout;
[0.12] call ACME_fnc_skCarouselRender;
call ACME_fnc_skBuildHotspots;
{private _c=_d displayCtrl _x; if (!isNull _c) then {_c ctrlEnable false;};} forEach [84150,84151,84154,84470,84820];

[{
    params ["_stableId","_size","_remainingFrac","_bodyPart","_siteIdx","_route"];
    disableSerialization;
    private _d = findDisplay 84000;
    if (isNull _d || {!(uiNamespace getVariable ["ACME_SK_InjectionBusy",false])}) exitWith {
        uiNamespace setVariable ["ACME_SK_InjectionBusy",false];
        uiNamespace setVariable ["ACME_SK_CarouselBusy",false];
    };
    private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
    if (([_stableId,_store] call ACME_fnc_skSelectStored) < 0) exitWith {
        uiNamespace setVariable ["ACME_SK_InjectionBusy",false];
        uiNamespace setVariable ["ACME_SK_CarouselBusy",false];
        uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
        [0.10] call ACME_fnc_skCarouselRender;
        call ACME_fnc_skBodyActionRender;
    };

    playSound "ACME_SyringePush";
    private _bar = _d displayCtrl 84420;
    private _pl = _d displayCtrl 84422;
    if (!isNull _bar && {!isNull _pl}) then {
        private _br = +(ctrlPosition _bar);
        private _native = _d getVariable ["ACME_SK_CarouselNativeRect",[0,0,1,1]];
        private _travel10 = _d getVariable ["ACME_SK_CarouselTravel10",safeZoneH*0.17];
        private _sizeRatio = switch (_size) do {case 1:{10.2/10.5};case 3:{9.83/10.5};case 5:{10.3/10.5};default{1};};
        private _targetY = (_br select 1) + (_travel10 * _sizeRatio * _remainingFrac * ((_br select 3) / (((_native select 3) max 0.001))));
        _pl ctrlSetPosition [_br select 0,_targetY,_br select 2,_br select 3];
        _pl ctrlCommit 3.0;
    };

    [{
        params ["_stableId","_bodyPart","_siteIdx","_route"];
        disableSerialization;
        private _d = findDisplay 84000;
        if (isNull _d) exitWith {
            uiNamespace setVariable ["ACME_SK_InjectionBusy",false];
            uiNamespace setVariable ["ACME_SK_CarouselBusy",false];
        };
        private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
        if (([_stableId,_store] call ACME_fnc_skSelectStored) >= 0) then {
            uiNamespace setVariable ["ACME_SK_SiteIdx",_siteIdx];
            uiNamespace setVariable ["ACME_SK_Route",_route];
            // Unlock immediately before the authoritative commit so its normal refresh/removal path can repaint.
            uiNamespace setVariable ["ACME_SK_InjectionBusy",false];
            uiNamespace setVariable ["ACME_SK_CarouselBusy",false];
            uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
            [_bodyPart] call ACME_fnc_skInjectSite;
        } else {
            uiNamespace setVariable ["ACME_SK_InjectionBusy",false];
            uiNamespace setVariable ["ACME_SK_CarouselBusy",false];
            uiNamespace setVariable ["ACME_SK_PendingInjection",[]];
        };
        uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",diag_tickTime + 1.00];
        {private _c=_d displayCtrl _x; if (!isNull _c) then {_c ctrlEnable true;};} forEach [84150,84151,84154,84470,84820];
        [0.10] call ACME_fnc_skCarouselRender;
        call ACME_fnc_skBuildHotspots;
        call ACME_fnc_skBodyActionRender;
    },[_stableId,_bodyPart,_siteIdx,_route],3.0] call CBA_fnc_waitAndExecute;
},[_stableId,_size,_remainingFrac,_bodyPart,_siteIdx,_route],0.14] call CBA_fnc_waitAndExecute;
true
