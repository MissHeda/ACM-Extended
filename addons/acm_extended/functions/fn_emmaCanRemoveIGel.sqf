// the patient-side condition for "Remove EMMA from their i-gel".
// it shows only on another patient with an oral SGA or i-gel and an EMMA attached.
// _this is [_medic, _patient].
params [["_medic", objNull], ["_patient", objNull]];

if (isNull _medic || {isNull _patient}) exitWith {false};
if (_patient isEqualTo _medic) exitWith {false};
if !(_patient isKindOf "CAManBase") exitWith {false};
if !(_patient getVariable ["ACME_emma_igelAttached", false]) exitWith {false};

// if the i-gel or SGA is no longer present, still allow the removal of stale EMMA state, so the HUD and the action
// cannot get stuck after airway changes.
true
