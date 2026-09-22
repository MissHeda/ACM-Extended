/*
 * Author: Blue (ACM). de-macroed + bug-fixed by ACM Extended
 * Inspect chest of patient (LOCAL).
 *
 * This is a de-macroed copy of ACM's breathing\functions\fnc_inspectChestLocal.sqf. It preserves
 * ACM's assessment logic, fixes the secondary tracheal-deviation log entry, and adds the obtunded
 * prone-to-supine care transition. Original log fix: the secondary tracheal-deviation log entry did `_logArray + _hintSecondLog`, but _hintSecondLog
 * is a STRING (not an array), so `array + string` threw "Generic error in expression" and the second
 * log line never wrote. Corrected to `_logArray + [_hintSecondLog]`.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 *
 * Return Value: None
 */

params ["_medic", "_patient"];
if (isNull _patient) exitWith {};

// B49: no obtunded-specific repositioning is performed here. If the treatment configuration requires the casualty
// supine, the ordinary treatment/roll path owns that movement exactly as it does for any other patient.

private _hintArray = ["%1", "STR_ACM_Breathing_InspectChest_Normal"];
private _hintLogArray = ["STR_ACM_Breathing_InspectChest_Normal"];
private _hintLogFormat = "%1 %2: %3";

private _hintSecondLog = "";
private _hintHeight = 1.5;

private _pneumothorax = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0] > 0;
private _tensionPneumothorax = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _hemothorax = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0] > 0.5;
private _tensionHemothorax = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0] > 1.4;

private _hasPneumothorax = _pneumothorax || _tensionPneumothorax;

private _trachealDeviationTime = CBA_missionTime - (_patient getVariable ["ACM_breathing_TensionPneumothorax_Time", CBA_missionTime]);

private _respiratoryArrest = ((_patient getVariable ["ACM_breathing_RespirationRate", 18]) < 1 || ((_patient getVariable ["ace_medical_heartRate", 80]) < 20) || !(alive _patient) || _tensionPneumothorax || _tensionHemothorax);
private _airwayBlocked = ([_patient] call ACM_airway_fnc_getAirwayState) == 0;

private _secondEntry = false;

switch (true) do {
    case (_respiratoryArrest || _airwayBlocked): {
        _hintArray set [1, "STR_ACM_Breathing_InspectChest_None"];
        _hintLogArray set [0, "STR_ACM_Breathing_InspectChest_None_Short"];

        if (_hasPneumothorax) then {
            _hintArray set [0, "%1<br/>%2"];
            _hintArray pushBack "STR_ACM_Breathing_InspectChest_None_Uneven";

            _hintLogArray pushBack "STR_ACM_Breathing_InspectChest_None_Uneven_Short";
            _hintLogFormat = "%1 %2: %3, %4";

            _hintHeight = 2;

            if (_trachealDeviationTime > 200) then {
                _secondEntry = true;
                _hintHeight = 2.5;

                _hintArray set [0, "%1<br/>%2<br/>%3"];

                if (_trachealDeviationTime > 300) then {
                    _hintArray pushBack "STR_ACM_Breathing_InspectChest_TrachealDeviation";

                    _hintSecondLog = "STR_ACM_Breathing_InspectChest_TrachealDeviation_Short";
                } else {
                    _hintArray pushBack "STR_ACM_Breathing_InspectChest_TrachealDeviation_Slight";

                    _hintSecondLog = "STR_ACM_Breathing_InspectChest_TrachealDeviation_Slight_Short";
                };
            };
        };

        if (_hemothorax) then {
            _hintHeight = _hintHeight + 0.5;

            _hintArray set [0, (["%1<br/>%2",
                (["%1<br/>%2<br/>%3","%1<br/>%2<br/>%3<br/>%4"] select _secondEntry)
            ] select _hasPneumothorax)];

            _hintArray pushBack "STR_ACM_Breathing_InspectChest_Bruising";

            _hintLogArray pushBack "STR_ACM_Breathing_InspectChest_Bruising_Short";
            _hintLogFormat = ["%1 %2: %3, %4", "%1 %2: %3, %4, %5"] select _hasPneumothorax;
        };
    };
    case (_pneumothorax || _hemothorax): {
        // These findings can coexist. Keep every selected observation visible and logged.
        _hintArray set [0, "%1<br/>%2"];
        _hintArray pushBack "STR_ACM_Breathing_InspectChest_Uneven";
        _hintLogArray pushBack "STR_ACM_Breathing_InspectChest_Uneven_Short";
        _hintLogFormat = "%1 %2: %3, %4";
        _hintHeight = 2;

        if (_hemothorax) then {
            _hintHeight = 2.5;
            _hintArray set [0, "%1<br/>%2<br/>%3"];
            _hintArray pushBack "STR_ACM_Breathing_InspectChest_Bruising";
            _hintLogArray pushBack "STR_ACM_Breathing_InspectChest_Bruising_Short";
            _hintLogFormat = "%1 %2: %3, %4, %5";
        };
    };
    default {};
};

// ACME: a tube down one bronchus.
// the switch above only reports uneven chest rise for a pneumothorax or a hemothorax, so a right mainstem
// intubation produced no chest finding at all. that is the one case where looking at the chest is the fastest way
// to the answer, and it was the one case the assessment stayed silent on.
// fn_ettmainstemtick already describes this in its header as part of the picture: the capnograph stays reassuring
// because the tube is in the trachea, the saturation drifts, the pressure climbs, and the chest moves on one side.
// three of those four were real and the fourth was not.
// the tube goes down the right main bronchus, because that bronchus leaves the trachea at a shallower angle than
// the left. so the right lung takes the whole tidal volume and the left does not move. the side is fixed by
// anatomy rather than rolled, which is why it is named here rather than stored on the patient.
// it is reported outside the switch instead of as another case, because a mainstem can sit on top of a
// pneumothorax and the medic should be told about both.
if (_patient getVariable ["ACME_ETT_Mainstem", false]) then {
    private _hc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
    private _idx = count _hintArray;
    _hintArray set [0, (_hintArray select 0) + "<br/>%" + (str _idx)];
    _hintArray pushBack (if (_hc) then {"Asymmetric chest rise, absent on the left"} else {"The left side of the chest is not moving"});
    _hintLogArray pushBack (if (_hc) then {"asymmetric rise, absent left"} else {"left chest not moving"});
    _hintLogFormat = _hintLogFormat + ", %" + (str ((count _hintLogArray) + 2));
    _hintHeight = _hintHeight + 0.5;
};

// hardcore descriptors: append the provider findings a trained eye would note, meaning how many chest seals are on
// the front against the rear, and the needle-decompression laterality, a unilateral left or right NCD or a
// bilateral NCD.
if (((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true)) then {
    private _extra = [];
    private _holes = _patient getVariable ["ACME_CS_holeData", []];  // [side, x, y, found, sealed, tex]
    private _sf = {((_x param [0,""]) == "front") && {_x param [4, false]}} count _holes;
    private _sr = {((_x param [0,""]) == "back")  && {_x param [4, false]}} count _holes;
    if (_sf > 0 || {_sr > 0}) then { _extra pushBack (format ["Chest seals: %1 front, %2 rear", _sf, _sr]); };
    private _ncd = _patient getVariable ["ACME_CS_ncdPlacedSides", []];
    switch (count _ncd) do {
        case 1: { _extra pushBack (format ["Unilateral %1 NCD", ["Left","Right"] select ((toLower (_ncd select 0)) == "right")]); };
        case 2: { _extra pushBack "Bilateral NCD"; };
        default {};
    };
    if !(_extra isEqualTo []) then {
        private _idx = count _hintArray;  // next %n argument slot
        _hintArray set [0, (_hintArray select 0) + "<br/>%" + (str _idx)];
        _hintArray pushBack (_extra joinString "   ");
        _hintHeight = _hintHeight + 0.5;
    };
};

private _logArray = [[_medic, false, true] call ace_common_fnc_getName, "STR_ACM_Breathing_InspectChest_ActionLog"];

// 3.4, chest wall bruising. this file emits through CBA_fnc_targetEvent, and ACE registered that event with
// LINKFUNC, which in a release build captures the ORIGINAL function value rather than resolving the global at
// call time. so the displayTextStructured wrapper installed in fn_postInit never sees this call. the keys are
// mapped here instead, which is why only this one surface needed touching by hand.
// only the bruising rows change. chest excursion, the uneven rows and both tracheal deviation rows stay in
// ACM's wording in both registers.
{
    if (_x isEqualType "") then {
        private _c = [_x] call ACME_fnc_clinTerm;
        if (_c isNotEqualTo "") then { _hintArray set [_forEachIndex, _c]; };
    };
} forEach _hintArray;

["ace_common_displayTextStructured", [_hintArray, _hintHeight, _medic], _medic] call CBA_fnc_targetEvent;
[_patient, "quick_view", _hintLogFormat, (_logArray + _hintLogArray)] call ace_medical_treatment_fnc_addToLog;

if (_secondEntry) then {
    [_patient, "quick_view", "%1 %2: %3", (_logArray + [_hintSecondLog])] call ace_medical_treatment_fnc_addToLog;
};
