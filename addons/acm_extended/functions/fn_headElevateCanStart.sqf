// the condition for "Elevate Head to 30". it is offered on a casualty who is DOWN, and never on the medic
// themselves. it also requires the head not to already be elevated.
// the TBI physiology effect still only applies to TBI patients, and this simply gates the position action.
//
// DOWN MEANS UNCONSCIOUS OR IN THE ACM LYING STATE.
// the test was unconscious only. a casualty who is awake but still down, which is every casualty a medic works on
// after they come round, could not be put into semi-Fowler's and could not be repositioned. that is wrong: sitting
// a conscious casualty up is a normal thing to do to them, and the position matters to their physiology whether
// they are awake or not.
// the auto-lower watchdog in fn_headElevateStart already expects this. it lowers the head on death or on a drag
// or a carry, and it deliberately does not lower it because the casualty is awake.
// a conscious casualty gets themselves out of the position through the Get Up self-interaction, which routes
// through the getUp override and tears the elevation down first.
params [["_patient", objNull, [objNull]], ["_medic", objNull, [objNull]]];
if (isNull _patient || {!alive _patient}) exitWith {false};
if (_patient isEqualTo _medic) exitWith {false};  // never on self
private _down = (_patient getVariable ["ACE_isUnconscious", false])
             || {_patient getVariable ["ACM_core_Lying_State", false]};
if (!_down) exitWith {false};
if (_patient getVariable ["ACME_headElevated", false]) exitWith {false};
(_patient isKindOf "CAManBase")
