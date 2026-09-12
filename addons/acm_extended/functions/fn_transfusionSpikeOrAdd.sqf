// this is driven by the renamed spike bag button in the transfusion menu.
// it has two behaviors in loose-bag mode.
// 1. an in-place y refill, where the button reads "Add Bag". if the access line of the selected blood already
// carries a y line, hang the next unit straight onto it, dropping the spent [empty blood bag] marker and
// keeping the clamped saline reserve. this is the one in-place hang that remains, and it matches the original
// add bag behavior.
// 2. spike into stage, where the button reads "Spike Bag". any other bag is spiked with an administration set,
// which consumes one ACME_IVLine, and staged into the prepared iv sets of the medic as a single-bag set tagged
// by kind: "blood", "saline" or "premixed". it is later hung from the prepared list through hang set, in
// fn_hangpreparedset, which enforces the one-line-per-access-site rule.
// y blood sets are built on the separate spike y tubing button, in fn_transfusionytubing, as kind "yset".
private _display = findDisplay 86000;
if (isNull _display) exitWith {};

// prepared iv sets mode. the button is relabeled "Hang Set" and the list shows the stored sets, in overlay
// 86145. route the press to the set-hang path instead of the spike and stage logic below.
if (uiNamespace getVariable ["ACME_preparedListMode", false]) exitWith { call ACME_fnc_hangPreparedSet; };

private _right = _display displayCtrl 86005;  // idc_transfusionmenu_rightlistpanel, the available bags.
private _idx = lbCurSel _right;
if (_idx < 0) exitWith {
    ["Select a bag first.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

private _class = ((_right lbData _idx) splitString "|") param [0, ""];
if (_class isEqualTo "") exitWith {};

// the FBTK, the field blood transfusion kit, is not a blood product to pre-stage and it is not a y set. it is
// hung as a single bag that collects the patient's own blood, then becomes a usable blood unit when removed.
// that is native ACM behavior end to end. the spike, stage and y logic below treats anything whose class
// contains "blood" as a blood product, and fieldbloodtransfusionkit trips that, which broke it. so the kit is
// handed straight to ACM's native add bag, which hangs it to fill, and the removal is likewise handed to native
// in fn_transfusionpullbag, so it returns the filled blood. native addbag reads the same right-list selection
// this function does, so the pick carries over.
if ((_class find "FieldBloodTransfusionKit") >= 0) exitWith { call ACM_circulation_fnc_TransfusionMenu_AddBag; };

private _action = ((_right lbData _idx) splitString "|") param [1, ""];
// is it a cooler-sourced row? the available-list rows we add for cooler blood carry a trailing |COOLER
// marker.
private _fromCooler = ((((_right lbData _idx) splitString "|") param [2, ""]) == "COOLER");
// is it a used-bag row? the rows we add for pulled partial bags carry a |USED marker and the store id.
private _fromUsed = ((((_right lbData _idx) splitString "|") param [2, ""]) == "USED");

// re-hang a used bag. rebuild the pulled bag on the selected access with its exact remaining volume. the hung-bag
// entry is pushed straight onto IV_Bags, because the flow is derived from IV_Bags, so it hangs and runs from
// where it was left. a used ACME_SalineY keeps that type, so it re-hangs as the clamped y reserve, and onto an
// already-y'd site it simply joins the y. this branch fully owns the used case and never falls through to the
// loose-bag paths below.
if (_fromUsed) exitWith {
    private _usedId = ((_right lbData _idx) splitString "|") param [3, ""];
    private _target2 = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
    if (isNull _target2) exitWith {};
    private _bp2   = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
    private _iv2   = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
    private _site2 = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
    if (_bp2 isEqualTo "" || {_site2 < 0}) exitWith {
        ["Select an access site to hang the used bag on.", 3, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };
    private _used = ACE_player getVariable ["ACME_usedBags", []];
    private _ui = _used findIf { (_x param [0, ""]) isEqualTo _usedId };
    if (_ui < 0) exitWith {};
    (_used select _ui) params [["_uid", ""], ["_utype", ""], ["_uremVol", 0], ["_uAccessType", 0], ["_uBloodType", -1], ["_uOrigVol", 1000], ["_uName", ""]];

    private _bags2 = _target2 getVariable ["ACM_circulation_IV_Bags", createHashMap];
    private _arr2 = _bags2 getOrDefault [_bp2, []];
    // on a y'd site a pulled leg leaves an empty marker behind, and re-hanging into that slot, matching the marker
    // kind at the same site and iv, keeps the y structure and the indices stable. otherwise the bag is added as a
    // new entry.
    private _newEntry = [_utype, _uremVol, _uAccessType, _site2, _iv2, _uBloodType, _uOrigVol];
    private _wantMarker = ["ACME_EmptySaline", "ACME_Empty"] select (_utype in ["Blood", "FreshBlood", "FBTK"]);
    private _slot = _arr2 findIf {
        ((_x param [0, ""]) isEqualTo _wantMarker) && {(_x param [3, -1]) isEqualTo _site2} && {(_x param [4, true]) isEqualTo _iv2}
    };
    if (_slot >= 0) then { _arr2 set [_slot, _newEntry]; } else { _arr2 pushBack _newEntry; };
    _bags2 set [_bp2, _arr2];
    [_target2, _bags2] call ACME_fnc_ivBagsCommit;
    [_target2, _bp2, _iv2, _site2] call ACME_fnc_resumeSiteFlow;  // a stopped line starts flowing again on a re-hang.

    _used deleteAt _ui;
    ACE_player setVariable ["ACME_usedBags", _used, true];

    // a warmer re-assert. this branch had none, so a re-hung unit lost the warmed color, tag and rate. blood hung
    // with a warmer on hand runs warmed exactly like the other hang paths.
    if ((_utype in ["Blood", "FreshBlood"]) && {([ACE_player, "ACME_BloodWarmer"] call ace_common_fnc_getCountOfItem) >= 1}) then {
        [_target2, true, false, objNull, CBA_missionTime + 15, true] call ACME_fnc_bloodThermalStateCommit;
        ["Blood warmer inline.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
    };

    [format ["Re-hung %1 (%2 mL).", _uName, round _uremVol], 2.5, ACE_player] call ace_common_fnc_displayTextStructured;
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_target2, "activity", "%1 re-hung a used %2 (%3 mL)", [[ACE_player, false, true] call ace_common_fnc_getName, _uName, round _uremVol]] call ace_medical_treatment_fnc_addToLog;
    };
    if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then { [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList; };
    uiNamespace setVariable ["ACME_usedRowSig", "__force__"];
    uiNamespace setVariable ["ACME_coolerRowSig", "__force__"];
};

private _isBlood  = ((toLowerANSI _class) find "blood")  >= 0;
private _isSaline = ((toLowerANSI _class) find "saline") >= 0;
// the kind stored on a staged single-bag set: saline, blood or premixed, where premixed is any other carrier such
// as PlasmaLyte, mannitol, HTS or magnesium. only saline sets can become an infusion, through prep infusion, and
// blood and premixed are grayed.
private _kind = "premixed";
if (_isSaline) then { _kind = "saline"; } else { if (_isBlood) then { _kind = "blood"; }; };

private _target = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];

// a blood unit that is mid-y-pairing, armed for a y set, must not be spiked out from under the build.
if (_isBlood && {(missionNamespace getVariable ["ACME_yPending", ""]) == _class}) exitWith {
    ["This blood is armed for a Y set. Finish or clear the Y build first.", 3.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// a cooler draw to hand. a |COOLER selection has no loose bag, so draw the unit out now, from a carried cooler or
// a box within reach, and it becomes a normal loose unit for either the y refill or the spike and stage below.
// _fromCooler tells us it is cold. it only fires when nothing of this class is already loose, because a loose bag
// is always used first.
if (_isBlood && _fromCooler && {([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1}) then {
    private _cstore = ACE_player getVariable ["ACME_coolerStore", createHashMap];
    private _heldNow = ((uniformItems ACE_player) + (vestItems ACE_player) + (backpackItems ACE_player)) select { (_x find "ACME_BloodCooler_") == 0 };
    private _gotIt = false;
    {
        if (_gotIt) exitWith {};
        private _cc = _x;
        if (_cc in _heldNow) then {
            private _contents = _cstore getOrDefault [_cc, []];
            private _hit = _contents findIf { (_x param [0, ""]) isEqualTo _class };
            if (_hit >= 0) then { _contents deleteAt _hit; _cstore set [_cc, _contents]; [ACE_player, "store", _cstore, true] call ACME_fnc_coolerStateCommit; _gotIt = true; };
        };
    } forEach (keys _cstore);
    if (!_gotIt) then {
        {
            if (_gotIt) exitWith {};
            private _bx = _x;
            private _cargo = itemCargo _bx;
            private _i = _cargo find _class;
            if (_i >= 0) then { _cargo deleteAt _i; clearItemCargoGlobal _bx; { _bx addItemCargoGlobal [_x, 1]; } forEach _cargo; _gotIt = true; };
        } forEach (nearestObjects [ACE_player, ["ACME_BloodCoolerBox_CSWB1U", "ACME_BloodCoolerBox_CSWB2U", "ACME_BloodCoolerBox_CSWB4U"], 6]);
    };
    if (_gotIt) then {
        missionNamespace setVariable ["ACME_coolerAutoStoreSuppressUntil", diag_tickTime + 5];
        missionNamespace setVariable ["ACME_coolerAutoStoreBusy", true];
        ACE_player addItem _class;
        if (([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1) then {
            private _cont = objNull;
            { if (!isNull _x) exitWith { _cont = _x; }; } forEach [backpackContainer ACE_player, vestContainer ACE_player, uniformContainer ACE_player];
            if (!isNull _cont) then { _cont addItemCargoGlobal [_class, 1]; };
        };
        missionNamespace setVariable ["ACME_coolerAutoStoreBusy", false];
        uiNamespace setVariable ["ACME_coolerRowSig", "__force__"];
        if (!isNull (uiNamespace getVariable ["ACME_CLR_DLG", displayNull])) then { call ACME_fnc_coolerRefresh; };
    };
};

// the in-place y refill, "Add Bag". a selected blood on an already-y'd access line hangs straight onto it.
private _yBodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _yIV   = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _ySite = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
private _lineKey = format ["%1#%2#%3", _yBodyPart, _yIV, _ySite];
private _lineYd = _lineKey in (if (isNull _target) then {[]} else {_target getVariable ["ACME_YLines", []]});

if (_isBlood && _lineYd && {!isNull _target}) exitWith {
    private _bags = (_target getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_yBodyPart, []];
    private _hasActiveBlood = false;
    private _hasEmptySlot = false;
    {
        _x params [["_bt", ""], ["_bv", 0], "", ["_bsite", -1], ["_biv", true]];
        if (_bsite isEqualTo _ySite && {_biv isEqualTo _yIV}) then {
            if (_bt isEqualTo "ACME_Empty") then { _hasEmptySlot = true; };
            if ((_bt in ["Blood", "FreshBlood"]) && {_bv > 0.01}) then { _hasActiveBlood = true; };
        };
    } forEach _bags;
    private _dirtyNow = (_target getVariable ["ACME_YLineDirty", createHashMap]) getOrDefault [toLower (format ["%1#%2#%3", _yBodyPart, _yIV, _ySite]), false];

    if (_hasActiveBlood) exitWith {
        ["A unit is still running on this Y line.", 3, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };
    if (_dirtyNow) exitWith {
        ["Flush the line (Flush Line) before hanging the next unit.", 3, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };
    if (([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1) exitWith {
        ["Blood unit not on hand.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };

    // drop the spent [empty blood bag] marker so the new unit takes its slot. the clamped saline reserve stays.
    if (_hasEmptySlot) then {
        private _allBags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
        private _bp = _allBags getOrDefault [_yBodyPart, []];
        _bp = _bp select { !(((_x param [0, ""]) isEqualTo "ACME_Empty") && {(_x param [3, -1]) isEqualTo _ySite} && {(_x param [4, true]) isEqualTo _yIV}) };
        _allBags set [_yBodyPart, _bp];
        [_target, _allBags] call ACME_fnc_ivBagsCommit;
    };

    call ACM_circulation_fnc_TransfusionMenu_AddBag;  // ACM hangs the new unit on the y line.
    [_target, _yBodyPart, _yIV, _ySite] call ACME_fnc_resumeSiteFlow;  // a stopped line starts flowing on a refill.

    if (!(_lineKey in (_target getVariable ["ACME_YLines", []]))) then {
        private _yl = _target getVariable ["ACME_YLines", []];
        _yl pushBack _lineKey;
        [_target, _yl] call ACME_fnc_yLinesCommit;
    };

    // an inline blood warmer wins. otherwise a cooler-sourced unit hangs cold and starts the rewarm clock.
    if (([ACE_player, "ACME_BloodWarmer"] call ace_common_fnc_getCountOfItem) >= 1) then {
        [_target, true, false, objNull, CBA_missionTime + 15, true] call ACME_fnc_bloodThermalStateCommit;
        ["Blood warmer inline.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
        if (!isNil "ace_medical_treatment_fnc_addToLog") then {
            [_target, "activity", "Hung warmed blood: LifeWarmer Quantum [Warmed]", []] call ace_medical_treatment_fnc_addToLog;
        };
    } else {
        if (_fromCooler) then {
            [_target, false, true, CBA_missionTime, CBA_missionTime + 15, true] call ACME_fnc_bloodThermalStateCommit;
            ["Cold blood hung. Use the warmer.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
        };
    };
};

// the direct y-line saline reserve refill, "Add Bag", restored. a saline selected while this access site carries
// a y line with a dead or absent clamped reserve hangs straight onto the line and is retagged as the clamped
// reserve, ACME_SalineY, holding until flush line bleeds it. it mirrors the blood refill above and the
// empty-marker slot reuse.
// if a reserve is already live we do not take this path, and we never lock out. the saline falls through to the
// normal spike and stage path below, so it can still be spiked and hung as an additional bag. you spike bags or
// add to a y, and you are never blocked from using saline.
private _yReserveLive = false;
if (_isSaline && _lineYd && {!isNull _target}) then {
    private _bpCheck = (_target getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_yBodyPart, []];
    _yReserveLive = (_bpCheck findIf {
        ((_x param [0, ""]) in ["ACME_SalineY", "Saline"]) && {(_x param [4, true]) isEqualTo _yIV} && {(_x param [1, 0]) > 0.5}
    }) > -1;
};
if (_isSaline && _lineYd && {!isNull _target} && {!_yReserveLive}) exitWith {
    private _allBags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
    private _bp = _allBags getOrDefault [_yBodyPart, []];
    if (([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1) exitWith {
        ["Bag not on hand.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };

    // drop the spent [empty saline bag] marker on this exact iv or io, so the new reserve takes its slot.
    _bp = _bp select { !(((_x param [0, ""]) isEqualTo "ACME_EmptySaline") && {(_x param [4, true]) isEqualTo _yIV}) };
    _allBags set [_yBodyPart, _bp];
    [_target, _allBags] call ACME_fnc_ivBagsCommit;

    call ACM_circulation_fnc_TransfusionMenu_AddBag;  // ACM consumes the loose saline and hangs it on the y line.
    [_target, _yBodyPart, _yIV, _ySite] call ACME_fnc_resumeSiteFlow;  // a stopped line starts flowing on a refill.

    // clear the stale pin snapshot for this line, so the replacement reserve pins to its own, full volume instead of
    // being clamped back down to the near-zero snapshot of the drained bag. that was the 0 ml but not empty ghost
    // that blocked re-flushing. the pin loop re-snapshots on the next tick once the retag lands.
    private _pinKeyEx = format ["%1#%2#%3", toLower _yBodyPart, _yIV, _ySite];
    private _pinsEx = _target getVariable ["ACME_YPins", createHashMap];
    if (_pinKeyEx in _pinsEx) then {
        _pinsEx deleteAt _pinKeyEx;
        _target setVariable ["ACME_YPins", _pinsEx, true];
    };
    _target setVariable ["ACME_YPinRelease_" + _pinKeyEx, nil];

    // retag the just-hung saline as the clamped y reserve, which is the latest matching iv or io saline on this body
    // part. it is delayed so the attach settles. the retag must land, or the reserve would drain like a normal
    // drip.
    [{
        params ["_patient", "_bpName", "_iv2"];
        if (isNull _patient) exitWith {};
        private _bags2 = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
        private _arr = _bags2 getOrDefault [_bpName, []];
        private _sIdx = -1;
        {
            if (((_x param [0, ""]) == "Saline") && {(_x param [4, true]) isEqualTo _iv2}) then { _sIdx = _forEachIndex; };
        } forEach _arr;
        if (_sIdx >= 0) then {
            private _e = +(_arr select _sIdx);
            _e set [0, "ACME_SalineY"];
            _arr set [_sIdx, _e];
            _bags2 set [_bpName, _arr];
            [_patient, _bags2] call ACME_fnc_ivBagsCommit;
        };
    }, [_target, _yBodyPart, _yIV], 0.3] call CBA_fnc_waitAndExecute;
    ["Y saline reserve replaced.", 2.5, ACE_player] call ace_common_fnc_displayTextStructured;
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_target, "activity", "%1 replaced the Y line saline reserve", [[ACE_player, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
    };
};

// spike into stage. any bag not caught above is spiked and staged into the prepared iv sets.
private _setItem = "ACME_IVLine";
private _setName = "an IV line (administration set)";
if (([ACE_player, _setItem] call ace_common_fnc_getCountOfItem) < 1) exitWith {
    [format ["You need %1 to spike this bag.", _setName], 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};
if (([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1) exitWith {
    ["Bag not on hand.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};
// do not start a second spike while one is running.
if (count (missionNamespace getVariable ["ACME_spikingActive", []]) > 0) exitWith {};

// a "Spiking Bag..." beat on the button, then the commit, which consumes the iv line and the bag and stores a
// single-bag set.
missionNamespace setVariable ["ACME_spikingActive", [_class, diag_tickTime + 1.6]];
[{
    params ["_class", "_action", "_setItem", "_setName", "_kind", "_cold"];
    missionNamespace setVariable ["ACME_spikingActive", []];
    if (([ACE_player, _setItem] call ace_common_fnc_getCountOfItem) < 1) exitWith {
        [format ["%1 is no longer available.", _setName], 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };
    if (([ACE_player, _class] call ace_common_fnc_getCountOfItem) < 1) exitWith {
        ["The bag is no longer on hand.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
    };
    ACE_player removeItem _setItem;
    ACE_player removeItem _class;

    private _cfg = configFile >> "CfgWeapons" >> _class;
    private _nm = [getText (_cfg >> "displayName"), getText (_cfg >> "shortName")] select (isText (_cfg >> "shortName"));
    if (_nm isEqualTo "") then { _nm = _class; };
    private _label = format ["%1%2", _nm, ["", " [Cooled]"] select _cold];

    private _id = format ["set_%1_%2", floor (diag_tickTime * 1000), floor (random 100000)];
    private _rec = [_id, _class, _action, "", "", "", _label, _cold, _kind];
    private _sets = ACE_player getVariable ["ACME_preparedIVSets", []];
    _sets pushBack _rec;
    ACE_player setVariable ["ACME_preparedIVSets", _sets, true];
    uiNamespace setVariable ["ACME_preparedRowSig", "__force__"];

    ["Bag spiked and staged to Prepared IV sets.", 2, ACE_player] call ace_common_fnc_displayTextStructured;

    if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then {
        [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList;
    };
}, [_class, _action, _setItem, _setName, _kind, (_isBlood && _fromCooler)], 1.6] call CBA_fnc_waitAndExecute;
