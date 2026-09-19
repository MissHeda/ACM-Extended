// Create the same native rope and helper endpoints used by ACE fast-roping.
// Helpers attach to the units; the patient is NEVER attached to either helper.
// addForce on the patient owner supplies controlled pulling rather than transferring helper collisions.
params ["_patient","_medic",["_create",true]];
private _old = _patient getVariable ["ACME_dragHandle_ropeObjects",[]];
if !(_old isEqualTo []) then {
    ropeDestroy (_old param [0,objNull]);
    {if (!isNull _x) then {deleteVehicle _x;};} forEach (_old select [1]);
};
_patient setVariable ["ACME_dragHandle_ropeObjects",[],true];
if (!_create) exitWith {[]};
private _a = createVehicle ["ace_fastroping_helper",getPosATL _medic,[],0,"CAN_COLLIDE"];
private _b = createVehicle ["ace_fastroping_helper",getPosATL _patient,[],0,"CAN_COLLIDE"];
{
    _x allowDamage false;
    _x disableCollisionWith _medic;
    _x disableCollisionWith _patient;
    _x enableRopeAttach true;
} forEach [_a,_b];
_a disableCollisionWith _b;
_a attachTo [_medic,[0,-0.30,0.55]];
_b attachTo [_patient,[0,0,0],"Spine3",true];
private _length = missionNamespace getVariable ["ACME_dragHandle_slackLength",1.0];
_length = _length max (_a distance _b);
private _rope = ropeCreate [_a,[0,0,0],_b,[0,0,0],_length];
if (isNull _rope) exitWith {deleteVehicle _a; deleteVehicle _b; []};
private _objects = [_rope,_a,_b];
_patient setVariable ["ACME_dragHandle_ropeObjects",_objects,true];
_objects
