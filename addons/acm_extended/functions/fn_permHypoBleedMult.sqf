// permissive hypotension: bleeding scales with the pressure driving it.
// a wound bleeds because there is a pressure gradient across the hole. raise the mean arterial pressure and you
// push blood out of an uncontrolled wound faster, and you push soft fresh clot off it. that is the entire reason
// hypotensive resuscitation exists: in uncontrolled hemorrhage you resuscitate to a palpable radial pulse rather
// than to a textbook pressure, because chasing a normal number costs you the clot and the blood you just gave.
// until now nothing in the addon modeled it. fn_clotpoptick punished the wrong fluid, crystalloid into a
// hypovolaemic patient, and was indifferent to the pressure endpoint, so a medic could push a casualty to a
// normal pressure with whole blood and nothing tore loose. the teaching point never landed.
// the multiplier is simply proportional to the driving pressure: MAP divided by a reference MAP. that is the
// honest physical relationship and it needs no tuning curve to justify it. at the reference it is 1.0, so a
// casualty held at the target bleeds exactly as they did before this existed and nothing about the old balance
// moves.
// a MAP of 50 gives 0.71x, 70 gives 1.00x, 90 gives 1.29x and 110 gives 1.57x.
// it is clamped at both ends: a floor, because even a nearly pulseless casualty oozes, and a ceiling, because the
// model is a linear stand-in for something that stops being linear at extremes.
// the scope resolves itself. this multiplies the blood-loss and internal-bleeding channels of ACE, and ACE already
// returns zero from those for a wound that is bandaged or under a tourniquet. so it can only ever act on bleeding
// that is still uncontrolled, which is exactly the clinical scope, without having to enumerate body parts or
// wound types. controlled wounds multiply zero by something and stay zero.
// call it as [_unit] call ACME_fnc_permHypoBleedMult, which returns a multiplier, and 1.0 when the system is
// off.

params ["_unit"];
if (isNil "_unit" || {isNull _unit}) exitWith { 1 };
if !(missionNamespace getVariable ["ACME_sys_permHypo", true]) exitWith { 1 };

private _map = [_unit] call ACME_fnc_tbiGetMAP;
if (isNil "_map" || {!(_map isEqualType 0)} || {_map <= 0}) exitWith { 1 };

private _ref = (missionNamespace getVariable ["ACME_permHypo_refMAP", 70]) max 1;
private _lo  = missionNamespace getVariable ["ACME_permHypo_multMin", 0.55];
private _hi  = missionNamespace getVariable ["ACME_permHypo_multMax", 2.0];

((_map / _ref) max _lo) min _hi
