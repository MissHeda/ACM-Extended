// remove an 18g iv from a patient through ACM's own setiv, where gauge type 5 is the ACME 18g, the same type
// fn_place18g writes. it mirrors ACM's removeiv behavior: the catheter is a consumable, so it is not returned to
// inventory.
// _this is the ACE callback [_medic, _patient, _bodyPart, _args].
// _args is [_accessSite], where 0 is upper, 1 is middle and 2 is lower.
params ["_medic", "_patient", "_bodyPart", "_args"];
_args params [["_accessSite", 2]];
if (isNull _patient) exitWith {};

if (!isNil "ACM_circulation_fnc_setIV") then {
    [_medic, _patient, _bodyPart, 5, false, true, _accessSite] call ACM_circulation_fnc_setIV;
    // clear the extravasation-compromised flag for this specific iv, because it no longer exists to leak through.
    private _bpFlag = toLowerANSI _bodyPart; if (_bpFlag == "ej") then { _bpFlag = "head"; };
    _patient setVariable [format ["ACME_ivCompromised_%1_%2", _bpFlag, _accessSite], nil, true];
    private _siteName = ["upper", "middle", "lower"] select _accessSite;
    [format ["18G IV removed: %1 %2.", _siteName, ([_bodyPart, "display"] call ACME_fnc_bodyPartName)], 2, _medic] call ace_common_fnc_displayTextStructured;
    [_patient, "activity",
 "%1 removed an 18G IV (%2 %3)",
 "18g IV removed, %2 %3, %1",
 [[_medic, false, true] call ace_common_fnc_getName, _siteName, [_bodyPart, "short"] call ACME_fnc_bodyPartName]] call ACME_fnc_medLog;

    // clear the persistent hub picture too. the remove mode of the minigame converts the clicked hub mark to removed,
    // and this ACE-action path only cleared ACM's internal iv state, so the drawn catheter and hub stayed on the limb
    // and read as still being there.
    // each button press removes exactly one iv, so convert exactly one still-hub mark on this body part to removed,
    // with a puncture hole, which stops rendermarks from drawing it. converting one per call, rather than all the
    // hubs on the limb, keeps a second iv on the same limb drawn until it too is removed.
    // as a safety net, if ACM reports no iv of any site remains on this part, sweep any leftover hubs so a stale
    // picture can never outlive the last real iv.
    private _bpL = toLowerANSI _bodyPart;
    private _acmBp = if (_bpL == "ej") then { "head" } else { _bpL };
    private _marks = _patient getVariable ["ACME_IV_Marks", []];
    private _hole = format ["\acm_extended\ui\holes\hole%1_ca.paa", (floor random 8) + 1];
    private _changed = false;

    // does any iv still remain on this body part, at any access site?
    private _stillHasIV = false;
    if (!isNil "ACM_circulation_fnc_hasIV") then {
        {
            if ([_patient, _acmBp, 0, _x] call ACM_circulation_fnc_hasIV) exitWith { _stillHasIV = true; };
        } forEach [0, 1, 2];
    };

    // convert one hub on this part, the iv just pulled.
    private _oneDone = false;
    {
        _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind"];
        if (!_oneDone && {(toLowerANSI _mbp) == _bpL} && {_mkind == "hub"}) then {
            _x set [4, "removed"];
            _x set [5, _hole];
            _oneDone = true; _changed = true;
        };
    } forEach _marks;

    // a safety sweep: with no iv left on the part, no hub should remain drawn.
    if (!_stillHasIV) then {
        {
            _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind"];
            if ((toLowerANSI _mbp) == _bpL && {_mkind == "hub"}) then {
                _x set [4, "removed"];
                _x set [5, _hole];
                _changed = true;
            };
        } forEach _marks;
    };

    if (_changed) then {
        _patient setVariable ["ACME_IV_Marks", _marks, true];
        // version it too, so an open screen repaints the pulled iv without a reopen.
        _patient setVariable ["ACME_IV_MarkVer", (_patient getVariable ["ACME_IV_MarkVer", 0]) + 1, true];
        uiNamespace setVariable ["ACME_IV_MarkVerSeen", (_patient getVariable ["ACME_IV_MarkVer", 0])];
        // if the iv minigame display is currently open on this patient, re-render so the hub disappears live.
        if (!isNil "ACME_fnc_ivMinigameRenderMarks" && {!isNull (uiNamespace getVariable ["ACME_IV_Patient", objNull])} && {(uiNamespace getVariable ["ACME_IV_Patient", objNull]) isEqualTo _patient}) then {
            [] call ACME_fnc_ivMinigameRenderMarks;
        };
    };
};
