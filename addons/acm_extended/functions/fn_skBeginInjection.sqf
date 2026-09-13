/* B76: stage a Body Map administration target instead of pushing immediately.
   Clicking an IV/IO or IM site promotes the carousel and remembers only the target. The provider can then browse
   syringes and explicitly press the action button above Draw Syringe to administer the currently selected syringe. */
disableSerialization;
params ["_bodyPart"];
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body"}) exitWith {false};
if (uiNamespace getVariable ["ACME_SK_InjectionBusy",false]) exitWith {false};
if (uiNamespace getVariable ["ACME_SK_TagEditMode",false]) exitWith {false};

private _patient = uiNamespace getVariable ["ACME_SK_Patient",objNull];
if (isNull _patient) then {_patient = _d getVariable ["ACME_SK_ReturnPatient",objNull];};
if (isNull _patient) exitWith {false};
private _route = uiNamespace getVariable ["ACME_SK_Route","vascular"];
private _siteIdx = uiNamespace getVariable ["ACME_SK_SiteIdx",-1];
private _iv = _route != "im";
private _present = true;
if (_iv) then {_present = if (_siteIdx >= 0) then {[_patient,_bodyPart,0,_siteIdx] call ACM_circulation_fnc_hasIV} else {[_patient,_bodyPart,0] call ACM_circulation_fnc_hasIO};};
if (!_present) exitWith {false};
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
if (([_store] call ACME_fnc_skSelectedIndex) < 0) exitWith {false};

uiNamespace setVariable ["ACME_SK_PendingInjection",[_bodyPart,_siteIdx,_route]];
uiNamespace setVariable ["ACME_SK_DiscardArmedId",""];
uiNamespace setVariable ["ACME_SK_CarouselExpanded",true];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
[0.14] call ACME_fnc_skDynamicLayout;
[0.14] call ACME_fnc_skCarouselRender;
call ACME_fnc_skBuildHotspots;
call ACME_fnc_skBodyActionRender;
true
