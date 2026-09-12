/* Authoritative mutation gate for detached infusion-bag custody state. */
params [["_patient",objNull,[objNull]],["_bags",[],[[]]],["_public",true,[true]]];
if (isNull _patient) exitWith {false};
_patient setVariable ["ACME_detachedBags", _bags, _public];
true
