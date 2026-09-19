// Dragger-side request to release the handle.
params [["_medic",objNull,[objNull]],["_patient",objNull,[objNull]],["_reason","manual",[""]]];
if (isNull _medic) exitWith {};
if (isNull _patient) then {_patient = _medic getVariable ["ACME_dragHandle_patient",objNull];};
if (isNull _patient) exitWith {[_medic,objNull,_reason] call ACME_fnc_dragHandleStopMedic;};

if !(_medic getVariable ["ACME_dragHandle_stopPending",false]) then {
    _medic setVariable ["ACME_dragHandle_stopPending",true];
    [_patient,"dragHandleStop",[_patient,_medic,_reason]] call ACME_fnc_ownerDispatch;

    // One idempotent resend closes the only awkward network edge: a locality handoff that happens at exactly the
    // same time as release. If the patient is already gone/stopped, clean the provider locally instead.
    [{
        params ["_m","_p","_why"];
        if (isNull _m || {!local _m} || {!(_m getVariable ["ACME_dragHandle_stopPending",false])}) exitWith {};
        if (isNull _p
            || {!(_p getVariable ["ACME_dragHandle_active",false])}
            || {(_p getVariable ["ACME_dragHandle_dragger",objNull]) isNotEqualTo _m}) then {
            [_m,_p,_why] call ACME_fnc_dragHandleStopMedic;
        } else {
            [_p,"dragHandleStop",[_p,_m,_why]] call ACME_fnc_ownerDispatch;
        };
    },[_medic,_patient,_reason],1.0] call CBA_fnc_waitAndExecute;
};
