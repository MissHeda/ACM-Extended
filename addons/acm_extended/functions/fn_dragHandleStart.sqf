// Provider-side request to attach the ACME drag handle.
params [["_medic",objNull,[objNull]],["_patient",objNull,[objNull]]];
if !([_medic,_patient] call ACME_fnc_dragHandleCanStart) exitWith {false};
if (!local _medic) exitWith {false};

_medic setVariable ["ACME_dragHandle_pending",true];
[_patient,"dragHandleStart",[_patient,_medic]] call ACME_fnc_ownerDispatch;
true
