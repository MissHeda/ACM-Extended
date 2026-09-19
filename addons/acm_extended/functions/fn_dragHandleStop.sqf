// Dragger-side request to release the handle.
params [["_medic",objNull,[objNull]],["_patient",objNull,[objNull]],["_reason","manual",[""]]];
if (isNull _medic) exitWith {};
if (isNull _patient) then {_patient = _medic getVariable ["ACME_dragHandle_patient",objNull];};
if (isNull _patient) exitWith {[_medic,objNull,_reason] call ACME_fnc_dragHandleStopMedic;};

if !(_medic getVariable ["ACME_dragHandle_stopPending",false]) then {
    _medic setVariable ["ACME_dragHandle_stopPending",true];
    [_patient,"dragHandleStop",[_patient,_medic,_reason]] call ACME_fnc_ownerDispatch;
};
