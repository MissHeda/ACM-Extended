// "Hang Set": hang the selected stored prepared iv set onto the current access site. it is routed here from
// fn_transfusionspikeoradd when the prepared iv sets list mode is active and the spike button, relabeled "Hang
// Set", is pressed. this is the one hang and refill path in the menu, because there is no add bag.
// there are two kinds of set.
// "yset" is blood plus clamped saline, hung as a y line through the shared fn_ylineattach.
// "blood", "saline" and "premixed" are a single spiked bag, hung on its own.
// one line per access site is enforced here.
// a fresh site hangs.
// an empty slot on this line, from a spent unit, refills: drop the empty marker and hang the new bag. for a y line
// only a blood refill is allowed, and the clamped saline reserve stays.
// a unit still running on this site refuses.
// a set is single-use, so hanging it consumes it.
private _display = findDisplay 86000;
if (isNull _display) exitWith {};

private _setList = _display displayCtrl 86145;
private _row = if (!isNull _setList) then { lbCurSel _setList } else { -1 };
private _setId = if (_row >= 0) then { _setList lbData _row } else { "" };
if (_setId isEqualTo "") exitWith {
    ["Select a prepared IV set first.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

private _sets = ACE_player getVariable ["ACME_preparedIVSets", []];
private _setIdx = _sets findIf { (_x param [0, ""]) isEqualTo _setId };
if (_setIdx < 0) exitWith {
    ["That prepared set is no longer available.", 3, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    uiNamespace setVariable ["ACME_preparedRowSig", "__force__"];
};
private _rec = _sets select _setIdx;
_rec params [["_id", ""], ["_bloodClass", ""], ["_bloodAction", ""], ["_salineClass", ""], ["_salineAction", ""], ["_tied", ""], ["_label", ""], ["_bloodCold", false], ["_kind", "yset"], ["_bloodExactVol", 0], ["_salineExactVol", 0]];
private _isSingle = (_kind != "yset");

private _target = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
if (isNull _target) exitWith {
    ["No casualty selected.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};
private _bodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _iv       = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _site     = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
if !([_target,_bodyPart,_iv,_site] call ACME_fnc_transfusionAccessValid) exitWith {
    ["Establish and select an IV/IO before hanging this set.",2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;
};
private _lineKey  = format ["%1#%2#%3", _bodyPart, _iv, _site];

// a set that came off a patient, through remove-to-list, is tied to that patient. untied sets hang on anyone.
if (_tied != "" && {_tied != (netId _target)}) exitWith {
    ["This set was pulled from a different casualty and cannot be reused here.", 4, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// re-derive the hang actions from the current fluid tables by class, with the stored action as the fallback. it is
// deterministic for cooler blood and for standard saline and carriers, and the fallback covers a class not
// momentarily listed.
private _fa  = missionNamespace getVariable ["ACM_circulation_Fluids_Array", []];
private _fad = missionNamespace getVariable ["ACM_circulation_Fluids_Array_Data", []];
private _bi = _fa find _bloodClass;
if (_bi >= 0) then { _bloodAction = _fad param [_bi, _bloodAction]; };
if (!_isSingle) then {
    private _si = _fa find _salineClass;
    if (_si >= 0) then { _salineAction = _fad param [_si, _salineAction]; };
};
if (_bloodAction isEqualTo "") exitWith {
    ["Cannot reconstruct this set's contents. Rebuild it.", 3.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};
if (!_isSingle && {_salineAction isEqualTo ""}) exitWith {
    ["Cannot reconstruct this set's contents. Rebuild it.", 3.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// the site state, for the one-line-per-site rule.
private _lineYd = _lineKey in (_target getVariable ["ACME_YLines", []]);
private _siteBags = (_target getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_bodyPart, []];
private _activeBlood = (_siteBags findIf {
    ((_x param [3, -1]) isEqualTo _site) && {(_x param [4, true]) isEqualTo _iv} &&
    {((_x param [0, ""]) in ["Blood", "FreshBlood"])} && {(_x param [1, 0]) > 0.01}
}) > -1;
private _activeOther = (_siteBags findIf {
    ((_x param [3, -1]) isEqualTo _site) && {(_x param [4, true]) isEqualTo _iv} &&
    {!((_x param [0, ""]) in ["ACME_SalineY", "ACME_Empty", "ACME_EmptySaline"])} && {(_x param [1, 0]) > 0.01}
}) > -1;
private _dirty = (_target getVariable ["ACME_YLineDirty", createHashMap]) getOrDefault [toLower (format ["%1#%2#%3", _bodyPart, _iv, _site]), false];

// the one-line-per-site gate. it computes a refusal message, then exits once at the top level, so no nested
// exitwith is needed.
private _refuse = "";
if (!_isSingle) then {
    // a y set needs a clear site: no existing y line and no running single line.
    if (_lineYd) then { _refuse = "This IV spot already has a Y line."; };
    if (_refuse == "" && _activeOther) then { _refuse = "This IV/IO already has a line running."; };
} else {
    if (_lineYd) then {
        // an existing y line: only a blood unit can refill it, because the clamped saline reserve stays.
        if (_kind != "blood") then { _refuse = "This IV spot already has a Y line."; }
        else {
            if (_activeBlood) then { _refuse = "A unit is still running on this Y line."; };
            if (_refuse == "" && _dirty) then { _refuse = "Flush the line (Flush Line) before hanging the next unit."; };
        };
    } else {
        // a non-y site: refuse only if a unit is actively running. an empty slot or a fresh site is fine to hang on.
        if (_activeOther) then { _refuse = "This IV/IO already has a line running."; };
    };
};
if (_refuse != "") exitWith {
    [_refuse, 4, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};


private _prepared = ACE_player getVariable ["ACME_infusion_PreparedBags", []];
private _custom = _prepared findIf {(_x param [0, ""]) == _id};
if (_custom >= 0) exitWith {
    missionNamespace setVariable ["ACME_infusion_SelectedPreparedIndex", _custom];
    private _l = _display displayCtrl 86130;
    // GivePreparedBag accepts this stable set ID independently of list selection.
    [_id] call ACME_fnc_givePreparedBag;
};

// Premixed medication must be clamped and acknowledged before its setup dialog opens.
private _singleType = getText (configFile >> "ace_medical_treatment" >> "IV" >> _bloodAction >> "type");
private _medicatedPremix = (toLowerANSI _singleType) in keys (missionNamespace getVariable ["ACME_infusion_premixedByType", createHashMap]);
if (_isSingle && {_medicatedPremix}) exitWith {
    [_rec, _target, _bodyPart, _iv, _site, _bloodAction] call ACME_fnc_givePremixedSet;
};

// commit: consume the set before any attach that closes and reopens the dialog, because the list rebuild must see
// it gone.
_sets deleteAt _setIdx;
ACE_player setVariable ["ACME_preparedIVSets", _sets, true];
uiNamespace setVariable ["ACME_preparedRowSig", "__force__"];

if (!_isSingle) exitWith {
    // a y set. bank the cold flag so the unit still hangs [cooled], and register the y line and the blood into saline
    // pairing.
    if (_bloodCold) then {
        private _yc = ACE_player getVariable ["ACME_ySetsCooled", createHashMap];
        _yc set [_bloodClass, (_yc getOrDefault [_bloodClass, 0]) + 1];
        ACE_player setVariable ["ACME_ySetsCooled", _yc, true];
    };
    private _yl = _target getVariable ["ACME_YLines", []];
    if (!(_lineKey in _yl)) then { _yl pushBack _lineKey; [_target, _yl] call ACME_fnc_yLinesCommit; };
    private _pair = ACE_player getVariable ["ACME_yPairSaline", createHashMap];
    _pair set [_bloodClass, _salineClass];
    ACE_player setVariable ["ACME_yPairSaline", _pair, true];

    ["Hanging Y set...", 2.5, ACE_player] call ace_common_fnc_displayTextStructured;
    [_target, _bodyPart, _iv, _site, _lineKey, _bloodClass, _bloodAction, _salineClass, _salineAction] call ACME_fnc_yLineAttach;
    [_target, _bodyPart, _iv, _site] call ACME_fnc_resumeSiteFlow;  // hanging a set on a stopped site starts it flowing.

    // if either leg came from a pulled, used bag, the set consumed a full standard item, so restore the exact remaining
    // volume of that leg onto the just-hung bag. ACM items are fixed-size and the exact ml only lives on a hung bag.
    // it is delayed so yLineAttach has settled the bags in IV_Bags. it is the same in-place edit the saline-reserve
    // retag uses.
    if (_bloodExactVol > 0 || {_salineExactVol > 0}) then {
        [{
            params ["_target", "_bodyPart", "_site", "_iv", "_bVol", "_sVol"];
            if (isNull _target) exitWith {};
            private _bags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
            private _arr = _bags getOrDefault [_bodyPart, []];
            private _changed = false;
            {
                private _t = _x param [0, ""];
                if (((_x param [3, -1]) isEqualTo _site) && {(_x param [4, true]) isEqualTo _iv}) then {
                    if (_bVol > 0 && {_t in ["Blood", "FreshBlood"]} && {(_x param [1, 0]) > _bVol}) then {
                        private _e = +_x; _e set [1, _bVol]; _arr set [_forEachIndex, _e]; _changed = true;
                    };
                    if (_sVol > 0 && {_t in ["ACME_SalineY", "Saline"]} && {(_x param [1, 0]) > _sVol}) then {
                        private _e = +_x; _e set [1, _sVol]; _arr set [_forEachIndex, _e]; _changed = true;
                    };
                };
            } forEach _arr;
            if (_changed) then { _bags set [_bodyPart, _arr]; [_target, _bags] call ACME_fnc_ivBagsCommit; };
        }, [_target, _bodyPart, _site, _iv, _bloodExactVol, _salineExactVol], 0.6] call CBA_fnc_waitAndExecute;
    };
};

// a single bag, either a fresh hang or a refill. drop any spent empty marker on this exact slot so the new bag
// takes its place. on a y blood refill that is only the empty blood marker, and the ACME_SalineY reserve is left
// untouched.
private _allBags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _bp = _allBags getOrDefault [_bodyPart, []];
private _before = count _bp;
_bp = _bp select {
    !( ((_x param [0, ""]) in ["ACME_Empty", "ACME_EmptySaline"]) && {(_x param [3, -1]) isEqualTo _site} && {(_x param [4, true]) isEqualTo _iv} )
};
if (count _bp != _before) then { _allBags set [_bodyPart, _bp]; [_target, _allBags] call ACME_fnc_ivBagsCommit; };

// hang the single bag on this access site.
[ACE_player, _target, _bodyPart, _bloodAction, objNull, _bloodClass, _iv, _site] call ace_medical_treatment_fnc_ivBag;
[_target, _bodyPart, _iv, _site] call ACME_fnc_resumeSiteFlow;  // hanging on a stopped site starts it flowing.

// blood: a warmer on hand wins, and otherwise a [cooled] unit hangs cold and starts the rewarm clock.
if (_kind isEqualTo "blood") then {
    if (([ACE_player, "ACME_BloodWarmer"] call ace_common_fnc_getCountOfItem) >= 1) then {
        [_target, true, false, objNull, CBA_missionTime + 15, true] call ACME_fnc_bloodThermalStateCommit;
        ["Blood warmer inline.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
        if (!isNil "ace_medical_treatment_fnc_addToLog") then {
            [_target, "activity", "Hung warmed blood: LifeWarmer Quantum [Warmed]", []] call ace_medical_treatment_fnc_addToLog;
        };
    } else {
        if (_bloodCold) then {
            [_target, false, true, CBA_missionTime, CBA_missionTime + 15, true] call ACME_fnc_bloodThermalStateCommit;
            ["Cold blood hung. Use the warmer.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
        };
    };
};

[_target, "activity", "%1 hung a prepared bag", [[ACE_player, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
["Hanging bag...", 2, ACE_player] call ace_common_fnc_displayTextStructured;

// rebuild the menu, so the new row and the decremented list show. it mirrors the close and reopen of addbag.
closeDialog 0;
[{
    params ["_p", "_bp2"];
    if (isNull _p) exitWith {};
    [ACE_player, _p, _bp2] call ACM_circulation_fnc_openTransfusionMenu;
}, [_target, _bodyPart], 0.3] call CBA_fnc_waitAndExecute;
