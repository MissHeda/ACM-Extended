// the ventilator travels with the casualty.
// this used to be a leash: a ventilator is joined to its patient by a short circuit, so walking away with the
// machine pulled it off. that modeled the circuit as tethered to the operator, which is backwards. a transport
// ventilator is strapped to the patient. it rides the litter with them, goes into the aircraft with them, and
// stays on them while the medic moves off to treat someone else. losing ventilation because the medic stepped
// away is not something that happens, and here it happened constantly.
// so there is no distance break any more, and no vehicle special case is needed either: if the machine is on the
// casualty, it is on the casualty, wherever they are and whoever is standing nearby. the only way off is a medic
// deliberately choosing disconnect ventilator, through ACME_fnc_ventDisconnectPatient.
// what is left here is bookkeeping: track which vehicle the casualty is in, because the rest of the vent code uses
// that to know where the machine physically is, and keep the operator pointer aimed at someone real.
// ACME_vent_leash remains registered as a setting and no longer severs anything.
// it runs server-side per configured patient, from fn_circhandle.
// call it as [_patient] call ACME_fnc_ventLeashTick.
params ["_patient"];
if !(missionNamespace getVariable ["ACME_sys_vent", true]) exitWith {};  // the system toggle. fully off means this stops.
if (isNull _patient) exitWith {};

// it is only meaningful while the machine is assigned to this patient. ACME_vent_configured survives a STOP VENT,
// which clears ACME_vent_connected while leaving the circuit on the tube, so either flag counts as still
// attached.
if (!(_patient getVariable ["ACME_vent_connected", false])
    && {!(_patient getVariable ["ACME_vent_configured", false])}) exitWith {};

// where the machine physically is. it is null when the casualty is on foot.
[_patient, "ACME_vent_mountVeh", (objectParent _patient)] call ACME_fnc_setVarNet;

// keep the operator link pointing at someone real. if whoever set the machine up is dead or gone, hand it to a
// conscious person nearby rather than dropping the casualty off the ventilator, because a machine does not stop
// working when the person who configured it leaves. if there is nobody, the machine keeps running regardless, and
// the operator pointer only decides who the panel and the sound engine treat as the owner.
private _medic = _patient getVariable ["ACME_vent_operator", objNull];
if (isNull _medic || {!alive _medic}) then {
    private _near = (_patient nearEntities ["CAManBase", 15]) select {
        alive _x
        && {_x isNotEqualTo _patient}
        && {!(_x getVariable ["ACE_isUnconscious", false])}
    };
    [_patient, "ACME_vent_operator", (_near param [0, objNull])] call ACME_fnc_setVarNet;
};
