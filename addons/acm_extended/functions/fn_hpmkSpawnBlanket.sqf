// spawn an HPMK blanket that has no collision of any kind.
// the problem: the blanket used to be a real createvehicle prop, Land_EmergencyBlanket_02_discarded_F. calling
// enableSimulationGlobal false stops its physics and does not remove its collision geometry, because that is
// baked into the model and is an engine-level fact. so a dropped blanket was a solid object: players stood on top
// of it, and ragdolls colliding with it got flung across the map.
// the fix splits the blanket into two things.
// 1. a DROPPED-blanket anchor, Land_HelipadEmpty_F. it is invisible and has no geometry at all, so it can never
// be collided with. it exists only after the HPMK is shed onto the ground, carries the pickup state, and gives ACE
// a shared interaction target.
// 2. a visual, a client-side createSimpleObject of the blanket model. dropped visuals attach to the dropped anchor;
// wrapped-patient visuals attach directly to the patient locally and never get a network anchor at all (B28).
// simple objects have no simulation, no damage and no collision. this is exactly the pattern ACE uses for litter.
// call it as [_class, _posatl] call ACME_fnc_hpmkSpawnBlanket, which returns a DROPPED-world anchor object.
params ["_class", "_pos"];
if (_class == "") exitWith { objNull };

// an invisible, geometry-free anchor. CAN_COLLIDE is irrelevant here, because there is nothing to collide with, and
// it is kept so the anchor lands exactly where asked rather than being nudged by the placement search of the
// engine.
private _anchor = createVehicle ["Land_HelipadEmpty_F", _pos, [], 0, "CAN_COLLIDE"];
_anchor enableSimulationGlobal false;
_anchor allowDamage false;
_anchor setPosATL _pos;

// broadcast the marker and which model to draw. the clients key their visuals off these.
_anchor setVariable ["ACME_hpmk_isBlanket", true, true];
_anchor setVariable ["ACME_hpmk_visualClass", _class, true];

_anchor
