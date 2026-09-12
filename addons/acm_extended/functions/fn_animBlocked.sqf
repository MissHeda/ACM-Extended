// should we suppress animation on this unit right now?
// inside a vehicle: always. there are no exceptions and no but-this-one-is-only-a-small-pose.
// arma's unit animations are authored for a unit standing on terrain. forcing one on a unit who is in a vehicle
// cargo seat fights the own seat animation of the vehicle for control of the same skeleton, and the engine
// resolves that badly: units get flung out of seats, welded half in and half out, stuck in a seat that no longer
// exists, or teleported to the vehicle origin. it is not cosmetic. it breaks the mission, and it breaks it for
// everyone who happens to be in that airframe.
// this applies to the patient and to the provider equally, and to every pose the addon owns: head elevation, direct
// pressure, chest inspection, the chest-seal roll, obtundation, HPMK wrapping, seizures and stance locks.
// if the unit is in a vehicle, the animation does not play. the treatment still happens, and only the theatre is
// cut.
// call it as [_unit] call ACME_fnc_animBlocked, which returns a bool.
params ["_unit"];
if (isNull _unit) exitWith {true};
!((vehicle _unit) isEqualTo _unit)
