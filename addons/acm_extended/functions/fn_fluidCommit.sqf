/* NA3 owner-only event ledger, called at the FINAL flow calculation, once per bag per native vitals update.
   drained mL leaves the bag; admitted mL reaches circulation. Their difference is not systemic medication. */
params ["_patient", "_part", "_index", "_bag", "_drained", "_admitted", "_dt", ["_flush", false]];
if (isNull _patient || {!local _patient} || {_drained <= 0}) exitWith {};
_admitted = (_admitted max 0) min _drained;
private _type = _bag param [0, ""];
if (_type == "Saline" || {_flush}) then {
    [_patient, "ACME_circ_salineGivenMl", (_patient getVariable ["ACME_circ_salineGivenMl", 0]) + _admitted] call ACME_fnc_setVarNet;
    _patient setVariable ["ACME_circ_salineTrackLastMl", _admitted, false];
    _patient setVariable ["ACME_circ_salineTrackLastAt", CBA_missionTime, false];
    _patient setVariable ["ACME_circ_salineTrackLastSource", "NA3 admitted-flow ledger", false];
};
if (_flush) exitWith {};
private _id = _bag param [8, ""];
if (_id == "") exitWith {};
private _entries = _patient getVariable ["ACME_infusion_BagMedications", []];
private _changed = false;
{
    private _e = _x;
    if ((_e param [23, ""]) != _id) then {continue;};
    private _conc = _e param [26, (_e param [13, 0]) / ((_e param [9, 1]) max 0.001)];
    private _remainingDose = _e param [14, 0];
    private _leavingDose = (_conc * _drained) min _remainingDose;
    private _systemicDose = _leavingDose * (_admitted / _drained);
    private _oldDriveSource = missionNamespace getVariable ["ACME_driveIsInfusion",false];
    missionNamespace setVariable ["ACME_driveIsInfusion",true];
    [_patient,_e select 12,_systemicDose,_dt] call ACME_fnc_medicationDriveAdd;
    missionNamespace setVariable ["ACME_driveIsInfusion",_oldDriveSource];
    // Exact bag/access identity and the SAME mass split used by patient fluid admission.
    [_patient,_part,if (_bag select 4) then {_bag select 3} else {-1},
        _e select 12,_leavingDose - _systemicDose,true] call ACME_fnc_medicationLeak;
    _e set [1, _part]; _e set [2, _index]; _e set [4, _bag select 3]; _e set [5, _bag select 4];
    _e set [10, ((_bag select 1) - _drained) max 0];
    _e set [14, (_remainingDose - _leavingDose) max 0];
    _e set [17, if (_dt > 0) then {_systemicDose / _dt} else {0}];
    _e set [18, CBA_missionTime];
    _e set [24, (_e param [24, 0]) + (_leavingDose - _systemicDose)];
    _e set [25, (_e param [25, 0]) + _systemicDose];
    if ((_e select 11) in (missionNamespace getVariable ["ACME_infusion_osmoticAgents", []])) then {
        private _stock = getNumber (configFile >> "ACM_Medication" >> "Concentration" >> (_e select 11) >> "concentration");
        if (_stock <= 0) then {_stock = switch (_e select 11) do {case "HTS3": {7500 / 250}; case "Mannitol": {100000 / 500}; default {0};};};
        if (_systemicDose > 0 && {_stock > 0}) then {[_patient, _e select 11, _systemicDose / _stock, true] call ACME_fnc_tbiApplyOsmotherapy;};
    } else {
        _e set [15, (_e param [15, 0]) + _systemicDose];
        [_patient, _e, (_e select 10) <= 0.01] call ACME_fnc_infusionDeliver;
    };
    _changed = true;
} forEach _entries;
if (_changed) then {
    [_patient, _entries] call ACME_fnc_infusionMedicationStateCommit;
    ACME_circ_activePatients pushBackUnique _patient;
};
