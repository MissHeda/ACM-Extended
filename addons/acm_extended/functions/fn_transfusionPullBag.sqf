// pull the selected hung bag off its access without tearing down the y tube. the bag is moved into the used bags
// store of the medic, ACME_usedBags on ACE_player, carrying its exact remaining volume, and it shows up in the
// available list, 86005, as a colored [Used] row that can be re-hung later, because fn_transfusionspikeoradd
// recognizes the |USED marker.
// on y structure persistence: pulling a bag from a y'd access does not delete its slot. the entry is retagged in
// place to the matching empty marker, [empty blood bag] as ACME_Empty and [empty saline bag] as
// ACME_EmptySaline, exactly as when a bag runs dry. that keeps the structure of the y line, and the index of
// every other bag, stable however many bags are pulled, and only discard y tubing tears the line down. on a
// plain, non-y access the slot is simply removed as before.
// it works from the transfusion list only. pull bag must never resolve to a drug infusion, because pulling the
// carrier out from under a running infusion is exactly the cross-contamination we are eliminating. so the target
// is taken solely from the transfusion list selection, 86004, rather than the infusions sub-list or a stale
// tracked pick that might have come from it.
// this is the exact-volume replacement of the mod for ACM's native remove bag, which rounds the return to 250,
// 500 or 1000 and discards anything under 250 ml. the action of the remove bag button is redirected here in
// config.
// call it as [] call ACME_fnc_transfusionPullBag.
private _display = findDisplay 86000;
if (isNull _display) exitWith {};
private _ctrlActive = _display displayCtrl 86004;

private _target   = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
private _bodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
if (isNull _target || {_bodyPart isEqualTo ""}) exitWith {};

private _ivBags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _arr = _ivBags getOrDefault [_bodyPart, []];

// resolve which hung bag to pull strictly from the transfusion list, 86004. there is no infusion-list path: if the
// medic has an infusions row selected and no transfusion row, pull bag does nothing rather than pulling the
// infused bag.
private _targetIndex = -1;
if (!isNull _ctrlActive) then {
    private _selArr = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selection_IVBags", []];
    private _live = lbCurSel _ctrlActive;
    if (_live >= 0 && {_live < count _selArr}) then { _targetIndex = (_selArr select _live) param [8, -1]; };
};
if (_targetIndex < 0 || {_targetIndex >= count _arr}) exitWith {
    ["Select a hung bag to pull.", 2, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

private _fnc_resetTrackers = {
    missionNamespace setVariable ["ACME_pull_selTrueIndex", -1];
    missionNamespace setVariable ["ACME_infusion_SelectedActiveInfusionTrueIndex", -1];
    missionNamespace setVariable ["ACME_infusion_SelectedActiveInfusionSelectionIndex", -1];
};

private _bag = +(_arr select _targetIndex);
_bag params [["_type", ""], ["_remVol", 0], ["_accessType", 0], ["_accessSite", -1], ["_iv", true], ["_bloodType", -1], ["_origVol", 1000]];

// the FBTK is collected and then removed exactly as native ACM does: the removal returns the filled blood unit,
// through generatefreshbloodentry, rather than a re-hangable used-bag row. hand it to ACM's native remove bag,
// pointed at the row of this bag, because native reads lbCurSel of the active list and maps it through
// selection_ivbags into a trueindex.
if (_type == "FBTK") exitWith {
    private _selArr = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selection_IVBags", []];
    private _selRow = _selArr findIf { (_x param [8, -1]) == _targetIndex };
    if (_selRow >= 0 && {!isNull _ctrlActive}) then { _ctrlActive lbSetCurSel _selRow; };
    call _fnc_resetTrackers;
    call ACM_circulation_fnc_TransfusionMenu_RemoveBag;
};

// is this access part of a y line? that decides the slot handling below.
private _onYLine = [_target, _bodyPart, _iv, _accessSite] call ACME_fnc_isYLineAccess;

// an empty-slot marker, a spent bag placeholder, has nothing to pull, so just clear it. it is an explicit
// tidy-up.
if (_type in ["ACME_Empty", "ACME_EmptySaline"]) exitWith {
    _arr deleteAt _targetIndex;
    _ivBags set [_bodyPart, _arr];
    [_target, _ivBags] call ACME_fnc_ivBagsCommit;
    call _fnc_resetTrackers;
    if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then { [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList; };
    uiNamespace setVariable ["ACME_coolerRowSig", "__force__"];
};

// a readable label for the used row.
private _name = switch (true) do {
    case (_type in ["Saline", "ACME_SalineY"]): { "Saline" };
    case (_type == "PlasmaLyte"): { "Plasma-Lyte A" };
    case (_type == "Mannitol"): { "Mannitol" };
    case (_type == "HTS"): { "Hypertonic Saline" };
    case (_type in ["Blood", "FreshBlood", "FBTK"]): {
        // ACM's own code-into-string map, through convertbloodtype, so o- reads as o-.
        private _bt = if (_bloodType >= 0 && {!isNil "ACM_circulation_fnc_convertBloodType"}) then {
            [_bloodType, 1] call ACM_circulation_fnc_convertBloodType
        } else { "" };
        format ["Blood%1", [" " + _bt, ""] select (_bt isEqualTo "")]
    };
    default { _type };
};

// if this bag carried a medicated infusion, the drip stops when the bag is pulled. drop only the record whose
// bagindex matches the pulled slot, because the relinker keeps bagindex honest, so an infusion running on the
// other leg of the y is untouched.
private _bagMeds = _target getVariable ["ACME_infusion_BagMedications", []];
private _wasInfusion = false;
if (count _bagMeds > 0) then {
    private _kept = _bagMeds select {
        !( ((_x param [1, ""]) isEqualTo _bodyPart) && {(_x param [2, -1]) isEqualTo _targetIndex}
           && {(_x param [4, -1]) isEqualTo _accessSite} && {(_x param [5, true]) isEqualTo _iv} )
    };
    if (count _kept != count _bagMeds) then {
        _wasInfusion = true;  // this bag carried a mixed drug, so it is a spent infusion, meaning trash. see below.
        [_target, _kept] call ACME_fnc_infusionMedicationStateCommit;
    };
};

// take the bag off the site. on a y line the slot is retagged in place to the matching empty marker, so the
// structure and the indices are preserved, the same as a bag running dry, and on a plain access the slot is
// removed. ACME_YLines is never touched here, because only discard y tubing removes a line.
if (_onYLine) then {
    private _e = +(_arr select _targetIndex);
    _e set [0, ["ACME_EmptySaline", "ACME_Empty"] select (_type in ["Blood", "FreshBlood", "FBTK"])];
    _e set [1, 0];
    _arr set [_targetIndex, _e];
} else {
    _arr deleteAt _targetIndex;
};
_ivBags set [_bodyPart, _arr];
[_target, _ivBags] call ACME_fnc_ivBagsCommit;
call _fnc_resetTrackers;  // the selection is consumed, so the next pull needs a fresh pick.

// a spent infusion, a saline carrier that had a drug mixed into it, is trash. it is not saved back as a
// re-hangable used bag and its carrier is not returned to inventory. only a plain, un-medicated bag is parked in
// the used-bag store with its exact remaining volume, so it can be re-hung later. the accesssite and iv are
// re-chosen at re-hang from the then-selected site, so they are not stored.
if (_wasInfusion) then {
    // release the roller-clamp throttle of this site, so the next bag hung here is not left at the dialled rate.
    private _pI = ACME_infusion_bodyParts find toLowerANSI _bodyPart;
    if (_pI >= 0 && {_accessSite >= 0}) then {
        _target setVariable [format ["ACME_clampRate_%1_%2_%3", _pI, _iv, _accessSite], -1];
    };
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_target, "activity", "%1 removed and discarded a spent %2", [[ACE_player, false, true] call ace_common_fnc_getName, _name]] call ace_medical_treatment_fnc_addToLog;
    };
    [format ["Discarded spent %1.%2", _name, ["", " Y tube intact."] select _onYLine], 2.5, ACE_player] call ace_common_fnc_displayTextStructured;
} else {
    private _id = format ["used_%1_%2", floor (diag_tickTime * 1000), floor (random 100000)];
    private _used = ACE_player getVariable ["ACME_usedBags", []];
    _used pushBack [_id, _type, _remVol, _accessType, _bloodType, _origVol, _name];
    ACE_player setVariable ["ACME_usedBags", _used, true];

    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_target, "activity", "%1 pulled a %2 (%3 mL left) to the used-bag set", [[ACE_player, false, true] call ace_common_fnc_getName, _name, round _remVol]] call ace_medical_treatment_fnc_addToLog;
    };
    [format ["Pulled %1 (%2 mL left).%3", _name, round _remVol, ["", " Y tube intact."] select _onYLine], 2.5, ACE_player] call ace_common_fnc_displayTextStructured;
};

// refresh the lists, so the freed leg and the new [used] row show at once.
if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then { [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList; };
uiNamespace setVariable ["ACME_coolerRowSig", "__force__"];
