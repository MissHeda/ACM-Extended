/* B14 owner settlement: immutable request identity, exact catheter generation, one mass split.
   Receipts survive full-heal for the SESSION so a delayed ACK cannot refund an accepted dose.
   No new exposure is produced by a duplicate, rejected request or drug still in line dead space. */
params ["_patient","_medic","_epoch","_id","_operation","_bodyPart",["_doses",[]],["_site",-2],["_identity",[]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient,"medicationLine",_this] call ACME_fnc_ownerDispatch;};
if (isNull _medic || {_id == ""}) exitWith {};
private _receipts = _patient getVariable ["ACME_medicationReceiptsB14",createHashMap];
private _reply = {
    params ["_accepted","_reason"];
    _receipts set [_id,[_accepted,_reason]];
    _patient setVariable ["ACME_medicationReceiptsB14",_receipts,true];
    ["ACME_medicationAck",[_medic,_id,_accepted,_reason],_medic] call CBA_fnc_targetEvent;
};
private _prior = _receipts getOrDefault [_id,[]];
if !(_prior isEqualTo []) exitWith {["ACME_medicationAck",[_medic,_id,_prior select 0,_prior select 1],_medic] call CBA_fnc_targetEvent;};
if (!alive _medic || {!alive _patient} || {_medic getVariable ["ACE_isUnconscious",false]}
    || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {[false,"patient/provider state changed"] call _reply};
if (_medic distance _patient > 5 && {isNull objectParent _medic || {objectParent _medic != objectParent _patient}}) exitWith {[false,"out of treatment range"] call _reply};
if !(_bodyPart in ["head","body","leftarm","rightarm","leftleg","rightleg"]
    && {_operation in ["administer","flush"]} && {_doses isEqualType []} && {_site in [-2,-1,0,1,2]}) exitWith {[false,"invalid route"] call _reply};
if (_operation == "administer" && {_doses isEqualTo []}) exitWith {[false,"empty dose"] call _reply};
if ((_doses findIf {!(_x isEqualType []) || {count _x < 4} || {!((_x select 1) isEqualType 0)}
    || {!finite (_x select 1)} || {(_x select 1) <= 0}
    || {!([_x select 0,_x select 2,true,_x param [5,false]] call ACME_fnc_medicationRouteAllowed)}}) >= 0) exitWith {[false,"unsupported component"] call _reply};
private _iv = _operation == "flush" || {(_doses findIf {_x select 2}) >= 0};
if (_iv && {!(_identity isEqualTo ([_patient,_bodyPart,_site] call ACME_fnc_medicationLineIdentity)) || {_identity isEqualTo []}}) exitWith {[false,"catheter removed or replaced"] call _reply};
private _pending = _patient getVariable ["ACME_pendingFlush",[]];
private _deliver = [];
if (_operation == "flush") then {
    private _keep = [];
    {
        if ((toLowerANSI (_x param [0,""])) == _bodyPart && {(_x param [5,-2]) == _site}
            && {(_x param [6,[]]) isEqualTo _identity}) then {
            _deliver pushBack [_x select 1,_x select 2,_x select 3,_x select 4,_x param [7,5],_x param [8,false]];
        } else {_keep pushBack _x;};
    } forEach _pending;
    _pending = _keep;
} else {
    private _flushMeds = missionNamespace getVariable ["ACME_flushReqMeds",[]];
    {
        _x params ["_class","_dose","_viaIV","_label",["_seconds",5],["_preparedMixture",false]];
        if !(_seconds isEqualType 0 && {finite _seconds} && {_seconds > 0}) then {_seconds = 5;};
        private _base = (_class splitString "_") select 0;
        private _park = missionNamespace getVariable ["ACME_flushReqEnabled",true]
            && {_viaIV} && {_base in _flushMeds} && {_label != "B13_MEASURED_EPI"};
        if (_park) then {_pending pushBack [_bodyPart,_class,_dose,true,_label,_site,_identity,_seconds,_preparedMixture];}
        else {_deliver pushBack [_class,_dose,_viaIV,_label,_seconds,_preparedMixture];};
    } forEach _doses;
};
// Unscheduled commit: reserve receipt and drain before callbacks can reenter.
_receipts set [_id,[true,"accepted"]];
_patient setVariable ["ACME_medicationReceiptsB14",_receipts,true];
_patient setVariable ["ACME_pendingFlush",_pending,true];
// B45: -1 is the exact IO line identity. An accepted medication push or flush is real fluid pressure through
// marrow, so it triggers the same immediate max-pain / delayed-syncope response as a running IO bag.
if (_iv && {_site == -1}) then {[_patient, _bodyPart, "fluid"] call ACME_fnc_ioPainResponse;};
{
    _x params ["_class","_dose","_viaIV","_label","_seconds","_preparedMixture"];
    private _fraction = if (_viaIV) then {[_patient,_bodyPart,_site] call ACME_fnc_medicationLineFraction} else {1};
    private _systemic = _dose * _fraction;
    if (_viaIV) then {[_patient,_bodyPart,_site,_class,_dose - _systemic,false] call ACME_fnc_medicationLeak;};
    if (_systemic > 0) then {
        [_patient,_bodyPart,_class,_systemic,_viaIV,false,[_site,_identity,_seconds,"bolus",_preparedMixture]] call ace_medical_treatment_fnc_medicationLocal;
    };
} forEach _deliver;
private _description = if (_operation == "flush") then {"Flushed selected catheter"} else {
    (_doses apply {format ["%1: %2 %3",_x select 3,_x select 1,if ((_x select 0) == "Hyaluronidase") then {"U"} else {"mg"}]}) joinString "; "
};
[_patient,"activity","%1: %2; %3 component(s) delivered, %4 queued on selected catheter.",
    [[_medic,false,true] call ace_common_fnc_getName,_description,count _deliver,count (_pending select {(_x select 0) == _bodyPart && {(_x select 5) == _site}})]] call ace_medical_treatment_fnc_addToLog;
[_patient,_description] call ace_medical_treatment_fnc_addToTriageCard;
[_patient] call ACME_fnc_ownerRegister;
[true,"accepted"] call _reply;
