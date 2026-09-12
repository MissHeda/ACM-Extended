// discard the y tubing on the currently selected access. this is the only action that tears a y line down, because
// pulling individual bags always leaves empty markers and keeps the structure, in fn_transfusionpullbag.
// discarding does the following.
// it pushes every bag on the access that still holds fluid into the used-bag store with its exact remaining volume,
// the same as pull bag, so nothing is wasted.
// it removes all bag entries for the access, both live bags and empty markers.
// it removes the key of the access from ACME_YLines, freeing the site for any other iv setup.
// it drops any medicated-infusion records still tied to the access.
// it does not refund a y-tubing set, because the tubing is consumed: it was cut off the line.
// it is wired to the repurposed 86120 button, "Discard Y Tubing", and is enabled only when the selected access
// carries a y.
// call it as [] call ACME_fnc_discardYTubing.
private _display = findDisplay 86000;
if (isNull _display) exitWith {};

private _target   = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
private _bodyPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _iv       = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _site     = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];
if (isNull _target || {_bodyPart isEqualTo ""} || {_site < 0}) exitWith {};

if !([_target, _bodyPart, _iv, _site] call ACME_fnc_isYLineAccess) exitWith {
    ["No Y tubing on this access.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

private _ivBags = _target getVariable ["ACM_circulation_IV_Bags", createHashMap];
private _arr = _ivBags getOrDefault [_bodyPart, []];

// sweep the access: salvage every bag still holding fluid into the used store and drop everything. it iterates in
// reverse so deleteat does not shift what is still to be visited.
private _used = ACE_player getVariable ["ACME_usedBags", []];
private _salvaged = [];
for "_i" from ((count _arr) - 1) to 0 step -1 do {
    private _e = _arr select _i;
    if (((_e param [3, -1]) isEqualTo _site) && {(_e param [4, true]) isEqualTo _iv}) then {
        _e params [["_type", ""], ["_remVol", 0], ["_accessType", 0], ["_aSite", -1], ["_aIv", true], ["_bloodType", -1], ["_origVol", 1000]];
        if (_remVol > 0.5 && {!(_type in ["ACME_Empty", "ACME_EmptySaline"])}) then {
            private _name = switch (true) do {
                case (_type in ["Saline", "ACME_SalineY"]): { "Saline" };
                case (_type == "PlasmaLyte"): { "Plasma-Lyte A" };
                case (_type == "Mannitol"): { "Mannitol" };
                case (_type == "HTS"): { "Hypertonic Saline" };
                case (_type in ["Blood", "FreshBlood", "FBTK"]): {
                    private _bt = if (_bloodType >= 0 && {!isNil "ACM_circulation_fnc_convertBloodType"}) then {
                        [_bloodType, 1] call ACM_circulation_fnc_convertBloodType
                    } else { "" };
                    format ["Blood%1", [" " + _bt, ""] select (_bt isEqualTo "")]
                };
                default { _type };
            };
            private _id = format ["used_%1_%2", floor (diag_tickTime * 1000), floor (random 100000)];
            _used pushBack [_id, _type, _remVol, _accessType, _bloodType, _origVol, _name];
            _salvaged pushBack (format ["%1 %2 mL", _name, round _remVol]);
        };
        _arr deleteAt _i;
    };
};
_ivBags set [_bodyPart, _arr];
[_target, _ivBags] call ACME_fnc_ivBagsCommit;
ACE_player setVariable ["ACME_usedBags", _used, true];

// remove the y key: the line is gone and the site is free for any other iv setup.
private _key = toLowerANSI (format ["%1#%2#%3", _bodyPart, _iv, _site]);
private _yLines = (_target getVariable ["ACME_YLines", []]) select { (toLowerANSI _x) isNotEqualTo _key };
[_target, _yLines] call ACME_fnc_yLinesCommit;

// if no other y line remains on this limb and route, retire its contamination flag too, so a future fresh y on the
// limb does not inherit a dirty state from tubing that no longer exists.
private _bpIvPrefix = toLowerANSI (format ["%1#%2#", _bodyPart, _iv]);
if (((_yLines apply { toLowerANSI _x }) findIf { (_x find _bpIvPrefix) == 0 }) < 0) then {
    private _dirty = _target getVariable ["ACME_YLineDirty", createHashMap];
    private _dKey = toLowerANSI (format ["%1#%2#%3", _bodyPart, _iv, _site]);
    if (_dKey in _dirty) then {
        _dirty deleteAt _dKey;
        _target setVariable ["ACME_YLineDirty", _dirty, true];
    };
};

// drop any medicated-infusion records still tied to this access, because their bags are gone.
private _bagMeds = _target getVariable ["ACME_infusion_BagMedications", []];
if (count _bagMeds > 0) then {
    private _kept = _bagMeds select {
        !( ((_x param [1, ""]) isEqualTo _bodyPart) && {(_x param [4, -1]) isEqualTo _site} && {(_x param [5, true]) isEqualTo _iv} )
    };
    if (count _kept != count _bagMeds) then { [_target, _kept] call ACME_fnc_infusionMedicationStateCommit; };
};

missionNamespace setVariable ["ACME_pull_selTrueIndex", -1];
missionNamespace setVariable ["ACME_infusion_SelectedActiveInfusionTrueIndex", -1];
missionNamespace setVariable ["ACME_infusion_SelectedActiveInfusionSelectionIndex", -1];

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_target, "activity", "%1 discarded the Y tubing", [[ACE_player, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
};
private _msg = if (_salvaged isEqualTo []) then { "Y tubing discarded." } else {
    format ["Y tubing discarded. Salvaged: %1.", _salvaged joinString ", "]
};
[_msg, 3.5, ACE_player] call ace_common_fnc_displayTextStructured;

if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then { [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList; };
uiNamespace setVariable ["ACME_coolerRowSig", "__force__"];
