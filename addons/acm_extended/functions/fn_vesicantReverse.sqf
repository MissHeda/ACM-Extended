// apply an extravasation antidote to the exposures on a body part.
// call it as [_patient, _bodyPart, _antidoteKind, _dose] call ACME_fnc_vesicantReverse.
// _antidoteKind is "phentolamine", which reverses the catecholamine vasopressors, norepinephrine and epinephrine,
// or "hyaluronidase", which reverses the hyperosmolar and irritant agents: calcium, HTS, mannitol, amiodarone,
// magnesium and esmolol.
// the correct antidote for the agent of an exposure stamps a strong reversal boost that the vesicant tick reads to
// accelerate recovery, further sped by elevation and a wrapped bruise. the wrong antidote does almost nothing.
// there is no other treatment for the injury itself: time, elevation, compression and the matching antidote.
params ["_patient", "_bodyPart", ["_antidoteKind", "hyaluronidase"], ["_dose", 0]];
// the system toggle, read live, so unticking extravasation in addon options stops this system immediately and
// completely with no mission restart.
if !(missionNamespace getVariable ["ACME_sys_vesicant", true]) exitWith {};
if (isNull _patient || {!local _patient}) exitWith {};
if (!(missionNamespace getVariable ["ACME_vesicant_enabled", true])) exitWith {};

if (!(_dose isEqualType 0) || {!finite _dose} || {_dose <= 0}) exitWith {};
private _referenceDose = if (_antidoteKind == "phentolamine") then {5} else {150}; // mg versus units
private _strength = (_dose / _referenceDose) min 1;
private _bp = toLowerANSI _bodyPart;
if (_bp == "ej") then { _bp = "head"; };

private _records = _patient getVariable ["ACME_vesicant_records", []];
private _now = CBA_missionTime;
private _matched = false;
private _wrongOnly = false;
private _candidate = [];
private _candidateScore = -1;
{
    _x params ["_key","_recBp","_classname"];
    if ((toLowerANSI _recBp) != _bp) then {continue};
    private _cur = _patient getVariable [_key,[]];
    if (_cur isEqualTo []) then {continue};
    private _correct = (_cur param [8,"hyaluronidase"]) == _antidoteKind;
    if (!_correct) then {_wrongOnly = true; continue};
    // Treat ONE exposure per infiltration: prefer the highest injury stage, then the most recently dosed record.
    private _stage = _cur param [2,-1];
    private _recent = _cur param [3,-1];
    private _score = ((_stage max -1) + 1) * 1000000 + (_recent max 0);
    if (_score > _candidateScore) then {_candidateScore = _score; _candidate = [_key,_cur,_classname];};
} forEach _records;
if !(_candidate isEqualTo []) then {
    _candidate params ["_key","_cur","_classname"];
    private _previous = if ((_cur param [11,-1]) >= 0 && {_now - (_cur select 11) <= (missionNamespace getVariable ["ACME_vesicant_antidoteWindowSec",90])}) then {_cur param [12,0]} else {0};
    _cur set [11,_now];
    _cur set [12,(_previous + _strength) min 1];
    _patient setVariable [_key,_cur,true];
    _matched = true;
};

if (_matched) then {
    [_patient, "dirty", true] call ACME_fnc_vesicantRegistryCommit;
    if (isNil "ACME_vesicant_patients") then { ACME_vesicant_patients = []; };
    ACME_vesicant_patients pushBackUnique _patient;
    private _label = if (_antidoteKind == "phentolamine") then { "Phentolamine" } else { "Hyaluronidase" };
    [format ["%1 given: reversing extravasation (%2).", _label, _bodyPart], 2, ACE_player] call ace_common_fnc_displayTextStructured;
} else {
    if (_wrongOnly) then {
        // the wrong antidote for the agent present: it does essentially nothing, leaving only the slow baseline recovery of
        // the tick as a teaching moment. give quiet feedback so the medic learns the agent and antidote pairing.
        private _label = if (_antidoteKind == "phentolamine") then { "Phentolamine" } else { "Hyaluronidase" };
        [format ["%1 given, but it is not the antidote for this agent.", _label], 2, ACE_player] call ace_common_fnc_displayTextStructured;
    };
};
