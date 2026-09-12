/* Physical support must still exist before an elevation benefit is applied. */
params ["_patient"];
if (isNull _patient || {!alive _patient} || {!(_patient getVariable ["ACME_headElevated", false])}
    || {_patient getVariable ["ACME_headElev_Suspended", false]}) exitWith {false};
private _hold = _patient getVariable ["ACME_headElev_hold", []];
if (_hold isEqualTo []) exitWith {true};
_hold params ["_medic", "_token"];
!isNull _medic && {isPlayer _medic} && {alive _medic} && {!(_medic getVariable ["ACE_isUnconscious", false])}
&& {(_medic getVariable ["ACME_headElev_holding", []]) isEqualTo [_patient, _token]}
&& {objectParent _medic == objectParent _patient}
&& {vehicle _medic == vehicle _patient
    || {([_medic, _patient] call ACME_fnc_patientInteractionDistance) <= (missionNamespace getVariable ["ace_medical_gui_maxDistance", 3])}}
