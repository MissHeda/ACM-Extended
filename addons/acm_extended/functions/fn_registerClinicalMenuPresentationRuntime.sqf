// ej injury list label. this shows "<gauge>g IV (EJ)" instead of "(Upper/Middle/Lower)".
// every head IV in this mod is an external jugular, so the mod relabels the access parenthetical to "(EJ)".
// ACM fires updateinjurylistpart with the entries array by reference just before it fills the listbox, so the
// mod edits it in place. it touches the head only, _selectionN 0, and keeps the gauge prefix and any " [bag]"
// suffix.
// core temperature is a whole body vital, so it goes on the general section beside bleeding, iv and pain status
// through updateinjurylistgeneral, not a per-part hook. fn_tempinjuryentry shows the last manual reading.
["ace_medical_gui_updateInjuryListGeneral", {_this call ACME_fnc_tempInjuryEntry}] call CBA_fnc_addEventHandler;
// B44 clinical airway-device descriptors: append patency for OPA/NPA/i-gel/ETT when unobstructed.
["ace_medical_gui_updateInjuryListPart", {_this call ACME_fnc_airwayInjuryRelabel}] call CBA_fnc_addEventHandler;
// ACM's injury list does not name types 5 and 6. Resolve by the actual site before EJ relabeling.
["ace_medical_gui_updateInjuryListPart", {
    params ["_ctrl", "_target", "_selectionN", "_entries"];
    if (isNull _target || {!(_selectionN in [0, 1, 2, 3, 4, 5])}) exitWith {};
    private _types = (_target getVariable ["ACM_circulation_IV_Placement", []]) param [_selectionN, []];
    [_entries, _types] call ACME_fnc_ivGaugeRelabel;
}] call CBA_fnc_addEventHandler;
["ace_medical_gui_updateInjuryListPart", {
    params ["_ctrl", "_target", "_selectionN", "_entries", "_bodyPartName"];
    if (_selectionN != 0) exitWith {};  // 0 = head
    private _labels = [
        localize "STR_ACM_Circulation_IV_Upper",
        localize "STR_ACM_Circulation_IV_Middle",
        localize "STR_ACM_Circulation_IV_Lower"
    ];
    {
        _x params ["_text", "_color"];
        private _new = _text;
        {
            private _find = format ["(%1)", _x];
            private _idx = _new find _find;
            if (_idx >= 0) then {
                _new = (_new select [0, _idx]) + "(EJ)" + (_new select [_idx + (count _find)]);
            };
        } forEach _labels;
        if (_new != _text) then { _entries set [_forEachIndex, [_new, _color]]; };
    } forEach _entries;
}] call CBA_fnc_addEventHandler;

// hardcore anatomical IV and IO site names in the injury list.
// this replaces the per-frame PFH that used to repaint control 1410 after ACE had filled it. ACM fires this
// event at fnc_updateInjuryList.sqf:564 with _entries BY REFERENCE and the IV rows already pushed at line 353,
// so the rows can be rewritten before they are ever drawn.
// the reason it had to move: the PFH read the limb out of the row text with (_lowT find "arm" >= 0), and ACM
// builds those rows as "16g IV (Middle)" with no limb word anywhere in them. that test was false on every row,
// so the leg branch was taken every time and arm IVs were labelled "16g IV (Great Saphenous)". the event hands
// over _selectionN, which is the actual limb.
// It runs after gauge and EJ corrections. Gauge labels are already resolved from each access site.
// The descriptor transform changes only the anatomical wording.
["ace_medical_gui_updateInjuryListPart", {
    params ["_ctrl", "_target", "_selectionN", "_entries"];
    if (_selectionN < 0) exitWith {};

    // the injury list header row, inventory section 2.
    // ACM pushes the selected part name at fnc_updateInjuryList.sqf:186. it is NOT entry 0: the general-tab
    // rows are still in the array at that point and a blank spacer is inserted at line 174 before it, so the
    // index moves. it is matched by content against the localized name for this exact _selectionN instead,
    // which also means only the one intended row can ever be hit.
    // this row is a listbox entry, not a fixed-width caption. the list already renders strings well past
    // twenty characters, "16g IV (Dorsal Venous Arch)" among them, so "Left Upper Extremity" fits with room.
    private _plainPart = "";
    private _longPart = "";
    if (_selectionN in [0, 1, 2, 3, 4, 5]) then {
        _plainPart = localize ([
            "STR_ACE_Medical_GUI_Head", "STR_ACE_Medical_GUI_Torso",
            "STR_ACE_Medical_GUI_LeftArm", "STR_ACE_Medical_GUI_RightArm",
            "STR_ACE_Medical_GUI_LeftLeg", "STR_ACE_Medical_GUI_RightLeg"
        ] select _selectionN);
        _longPart = [_selectionN, "long"] call ACME_fnc_bodyPartName;
    };

    {
        _x params ["_text", "_color"];
        private _new = _text;
        if (_plainPart isNotEqualTo "" && {_text isEqualTo _plainPart}) then {
            _new = _longPart;
        } else {
            _new = [_text, _selectionN, false] call ACME_fnc_ivSiteRelabel;
        };
        if (_new isNotEqualTo _text) then { _entries set [_forEachIndex, [_new, _color]]; };
    } forEach _entries;
}] call CBA_fnc_addEventHandler;

// limb stash for the medical log.
// ACM's setIVLocal carries the body part, at circulation/functions/fnc_setIVLocal.sqf:23, but the three places
// that LOG an access site all discard it. healingLogic is the one that matters: it fires this event at
// core/overrides/fnc_healingLogic.sqf:62 and writes its log line at 65 onward, on the same frame, with no
// medical menu open for ACME_fnc_ivLogRelabel to read a limb from.
// this is an ADDITIVE handler. ACM's own is registered in its XEH_postInit and still runs; this one only
// records what the event already carried.
// LOCAL on purpose, and read only within half a second. if healingLogic runs where the patient is remote the
// targetEvent lands on another machine, nothing is stashed here, and the log falls back to plain Upper, Middle
// or Lower exactly as it did before. that is the correct failure: a missing label beats a wrong vein.
["ACM_circulation_setIVLocal", {
    params ["_medic", "_patient", "_bodyPart", "_type", "_iv", "_accessSite"];
    if (isNull _patient) exitWith {};
    if (!_iv) exitWith {};  // IO carries no upper, middle or lower to relabel.
    _patient setVariable ["ACME_ivLastSite", [toLower _bodyPart, _accessSite, diag_tickTime]];
}] call CBA_fnc_addEventHandler;

// clinical wound type names, inventory section 4.1. ACM fires updateInjuryListWounds with _woundEntries by
// reference after all five wound categories are built and before they are appended, so the rows are rewritten
// before they are drawn rather than repainted afterwards.
["ace_medical_gui_updateInjuryListWounds", {_this call ACME_fnc_woundNameRelabel}] call CBA_fnc_addEventHandler;

// conditional bleeding status, inventory section 4.3. this is on the GENERAL tab, not the per-part one,
// because ACM builds both rows from IS_BLEEDING(_target) which is a whole-unit value.
["ace_medical_gui_updateInjuryListGeneral", {_this call ACME_fnc_bleedStatusRelabel}] call CBA_fnc_addEventHandler;

// AED vitals on every body part.
// ACM renders the AED monitor row, hr or pr, SpO2, bp and rr or CO2, on the torso only, on an arm that carries
// the pulse oximeter or the pressure cuff, and on the head with a capnograph. the legs never get it, and the
// medic must flip back to the torso to read vitals. when the AED connects through pads or any sensor, ACM's own
// hasaed "any" gate, the mod adds the same row to every body part ACM skipped. the entry text mirrors ACM's
// updateinjurylist builder with the macros expanded, so both rows read the same everywhere.
["ace_medical_gui_updateInjuryListPart", {
    params ["_ctrl", "_target", "_selectionN", "_entries"];
    if (isNull _target || {_selectionN < 0}) exitWith {};
    if (isNil "ACM_circulation_fnc_hasAED") exitWith {};
    if !([_target] call ACM_circulation_fnc_hasAED) exitWith {};

    // parts where ACM's own gate already rendered the row: the torso, an arm that holds the pulse ox or the
    // pressure cuff, and the head with a capnograph. a second row there would duplicate it.
    private _oxAt   = _target getVariable ["ACM_circulation_AED_Placement_PulseOximeter", -1];
    private _cuffAt = _target getVariable ["ACM_circulation_AED_Placement_PressureCuff", -1];
    private _capno  = _target getVariable ["ACM_circulation_AED_Placement_Capnograph", false];
    private _acmRendered = (_selectionN == 1)
        || {(_selectionN in [2,3]) && {(_oxAt == _selectionN) || {_cuffAt == _selectionN}}}
        || {(_selectionN == 0) && _capno};
    if (_acmRendered) exitWith {};

    private _padsStatus = _target getVariable ["ACM_circulation_AED_Placement_Pads", false];
    private _entry = localize "STR_ACM_Circulation_AED_Short";

    private _displayedHR = _target getVariable ["ACM_circulation_AED_Pads_Display", 0];
    if (_displayedHR < 1) then { _displayedHR = "--"; };
    _entry = _entry + (format [" [%1: %2", localize ([
        "STR_ACM_Circulation_AED_Monitor_PR",
        "STR_ACM_Circulation_AED_Monitor_HR"
    ] select _padsStatus), _displayedHR]);

    if (_oxAt != -1) then {
        private _displayedSPO2 = _target getVariable ["ACM_circulation_AED_PulseOximeter_Display", 0];
        if (_displayedSPO2 < 1) then { _displayedSPO2 = "--"; };
        _entry = _entry + (format [" %1: %2", localize "STR_ACM_Circulation_AED_Monitor_SpO2", _displayedSPO2]);
    } else {
        _entry = _entry + (format [" %1: --", localize "STR_ACM_Circulation_AED_Monitor_SpO2"]);
    };

    private _measuredBP = _target getVariable ["ACM_circulation_AED_NIBP_Display", [0,0]];
    private _displayedBP = _measuredBP;
    if ((_measuredBP select 1) < 1) then { _displayedBP = ["--","--"]; };
    _entry = _entry + (format [" %1: %2/%3", localize "STR_ACM_Circulation_AED_Monitor_BP", (_displayedBP select 0), (_displayedBP select 1)]);

    private _measuredEtCO2 = _target getVariable ["ACM_circulation_AED_CO2_Display", 0];
    private _measuredRR = _target getVariable ["ACM_circulation_AED_RR_Display", 0];
    if (_measuredEtCO2 > 0 && {_measuredRR > 0}) then {
        _entry = _entry + format [" %1: %2 %3: %4", localize "STR_ACM_Circulation_AED_Monitor_RR", _measuredRR, localize "STR_ACM_Circulation_AED_Monitor_CO2", _measuredEtCO2];
    } else {
        _entry = _entry + format [" %1: -- %2: --", localize "STR_ACM_Circulation_AED_Monitor_RR", localize "STR_ACM_Circulation_AED_Monitor_CO2"];
    };

    _entries pushBack [format ["%1]", _entry], [0.18, 0.6, 0.96, 1]];
}] call CBA_fnc_addEventHandler;
