// a full heal, from zeus heal, an ACM heal facility or ACE fullheal, all of which raise
// ace_medical_FullHeal locally on the patient, must heal fully. it clears every custom ACME ailment: the
// rhythm, the TBI and ICP, hypothermia, shock, edema, obtundation, vesicant, junctional, AAJT and XStat, and
// the active infusions. nothing survives the heal. death and respawn scrub the same state, so a casualty never
// carries a stale condition across either event.
["ace_medical_FullHeal", {_this call ACME_fnc_clearAllAilments}] call CBA_fnc_addEventHandler;
// AN IV PLACED BY ANY PATH GETS A HUB ON THE LIMB.
// ACM raises this event for every placement, so a second handler on the same name catches the auto heal
// facility path, a mission script, and anything else that calls setIV without knowing our mark list exists.
// without a hub there is nothing on the limb art to grab, so the line could not be seen and could not be pulled.
// fn_ivSeedHub defers its check by a beat and skips a site that already carries a hub, so the mini-game and the
// Zeus module, which write their own marks, never produce a duplicate.
["ACM_circulation_setIVLocal", {_this call ACME_fnc_ivSeedHub}] call CBA_fnc_addEventHandler;
// B57: death is also a hard clinical reset. ACME injury/evidence artifacts do not persist on the corpse.
addMissionEventHandler ["EntityKilled", { params ["_unit"]; if (local _unit) then { [_unit] call ACME_fnc_clearAllAilments; }; }];
// the EntityRespawned handler below covers respawn, and it now calls clearAllAilments as well.

// y-saline owner-side setup. this fires through CBA_fnc_targetEvent at the casualty, so the ACME_SalineY retag
// and the ACME_YLines registration happen on the machine that owns IV_Bags and runs the bag drainer. that
// defeats the race between the medic and the owner.
["ACME_ySalineSetup", {_this call ACME_fnc_ySalineSetup}] call CBA_fnc_addEventHandler;
