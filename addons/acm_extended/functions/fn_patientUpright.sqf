/* B56: is this patient upright, so a kneeling provider motion would be wrong?
   Upright means alive, conscious, standing or crouching on foot, and not in any lying, unconscious or cutscene
   state. Anything uncertain is treated as not upright, which keeps the established kneeling motions. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!alive _patient} || {!(_patient isKindOf "CAManBase")}) exitWith {false};
if (_patient getVariable ["ACE_isUnconscious", false]) exitWith {false};
if (!isNull objectParent _patient) exitWith {false};
if !((stance _patient) in ["STAND", "CROUCH"]) exitWith {false};
private _anim = toLower animationState _patient;
if ((_anim find "lying") >= 0 || {(_anim find "unconscious") >= 0} || {(_anim find "acts_") == 0}
    || {(_anim find "ainvppne") == 0} || {(_anim find "amovppne") == 0}) exitWith {false};
true
