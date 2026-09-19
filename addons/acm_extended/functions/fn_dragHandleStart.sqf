// Provider-side request to attach the ACME drag handle.
params [["_medic",objNull,[objNull]],["_patient",objNull,[objNull]]];
if !([_medic,_patient] call ACME_fnc_dragHandleCanStart) exitWith {false};
if (!local _medic) exitWith {false};

_medic setVariable ["ACME_dragHandle_pending",true];
[_patient,"dragHandleStart",[_patient,_medic]] call ACME_fnc_ownerDispatch;

// Never strand the interaction if locality churn prevents an acknowledgement. The owner transaction is still
// authoritative; this only releases the local UI gate so the medic can try again.
[{
    params ["_m"];
    if (!isNull _m && {local _m} && {_m getVariable ["ACME_dragHandle_pending",false]}
        && {isNull (_m getVariable ["ACME_dragHandle_patient",objNull])}) then {
        _m setVariable ["ACME_dragHandle_pending",false];
    };
},[_medic],3] call CBA_fnc_waitAndExecute;
true
