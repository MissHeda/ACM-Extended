/* Painful-procedure tolerance. Local lidocaine and systemic ketamine are separate gates.
   A systemic analgesic contribution can reduce procedure pain without being treated as local anaesthesia. */
params ["_patient", ["_bodyPart", "body"]];
if (isNull _patient) exitWith {false};
private _c = [_patient,_bodyPart] call ACME_fnc_proceduralAnalgesiaOnBoard;
private _local = _c select 0;
private _ket = _c select 1;
(_local >= (missionNamespace getVariable ["ACME_procLocalLidocaineThreshold",0.5]))
    || {_ket >= (missionNamespace getVariable ["ACME_procKetamineAnalgesiaThreshold",0.08])}
