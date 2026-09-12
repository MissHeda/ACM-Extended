/* B56: choose the provider state for a treatment pose, substituting a standing medicUp motion when the patient
   is upright. ACME_poseUprightStates in fn_postInit maps a pose mode to its candidate standing state. A
   candidate is used only if it exists in CfgMovesMaleSdr on this machine; otherwise the kneeling state is kept.

   Arguments: 0 mode, 1 kneeling state, 2 patient
   Return: [state, isUpright] */
params [["_mode", "", [""]], ["_kneel", "", [""]], ["_patient", objNull, [objNull]]];
if (_kneel == "" || {!([_patient] call ACME_fnc_patientUpright)}) exitWith {[_kneel, false]};
private _table = missionNamespace getVariable ["ACME_poseUprightStates", createHashMap];
private _candidate = _table getOrDefault [_mode, ""];
if !(_candidate isEqualType "") then {_candidate = "";};
if (_candidate == "") exitWith {[_kneel, false]};
if (isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _candidate)) exitWith {[_candidate, true]};
[_kneel, false]
