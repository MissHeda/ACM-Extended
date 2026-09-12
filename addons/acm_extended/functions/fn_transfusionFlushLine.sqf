private _p = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
if (isNull _p) exitWith {};
private _part = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _iv = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _site = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
[_p, "yFlush", [_p, ACE_player, _part, _iv, _site, [_p] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
