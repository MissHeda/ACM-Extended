/* Real new injury entry. Treatment/inspection/restore must use ptxEnsure. */
params [["_patient",objNull,[objNull]],["_severity",1,[0]]];
if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
if (!finite _severity) then {_severity=1;};
_severity=_severity max 0.1 min 3;
private _s=[_patient] call ACME_fnc_ptxEnsure;
private _air=(((_s select 1)+_severity) max 1) min 32;
_s set [1,_air];
_s set [2,((_s select 2)+0.25*_severity) min 1];
_s set [3,0];
_s set [6,(_s select 6)+1];
_s set [8,(_s select 8) max (_air min 1)];
[_patient, true] call ACM_breathing_fnc_setChestInjuryState;
[_patient,_s,_patient getVariable ["ACM_breathing_TensionPneumothorax_State",false]] call ACME_fnc_ptxPublish;
private _patients=missionNamespace getVariable ["ACME_clinical_activePatients",[]];
_patients pushBackUnique _patient;
missionNamespace setVariable ["ACME_clinical_activePatients",_patients];
