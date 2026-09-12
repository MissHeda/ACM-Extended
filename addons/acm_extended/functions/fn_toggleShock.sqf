// induce or clear the fluid-refractory peri-arrest shock state on a patient.
// this is the scenario hook, for a medic or zeus, for the crashing-but-perfusing patient that push-dose epi is for:
// acute severe hypotension that volume cannot fix.
// the onset is immediate: the severity snaps to full and the bp drop is applied on the spot, so the patient crashes
// the moment the button is pressed, with no creep-in delay.
// it stays absolute and fluid-refractory: only pressor and push-dose support, added back in fn_circhandle, lifts the
// effective MAP back over the MAP-under-55 arrest line of ACM.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};

private _state = _patient getVariable ["ACME_circ_State", createHashMap];
private _active = _state getOrDefault ["shockActive", false];

if (_active) then {
    _state set ["shockActive", false];
    _state set ["shockSeverity", 0];
    [_patient, _state] call ACME_fnc_circStateCommit;
    _patient setVariable ["ACME_circ_bpOffset", 0, true];
    _patient setVariable ["ACME_hrTarget_circ", -1, true];  // release hr back to ACM immediately
    ["Peri-arrest shock cleared.", 2, _medic] call ace_common_fnc_displayTextStructured;
} else {
    _state set ["shockActive", true];
    _state set ["shockSeverity", 1];  // full immediately -> instant crash
    _state set ["lastTick", CBA_missionTime];
    [_patient, _state] call ACME_fnc_circStateCommit;
    ACME_circ_activePatients pushBackUnique _patient;

    // apply the bp drop now so it lands this instant rather than on the next handler tick: pull the effective MAP
    // straight down to the shock floor, below 55.
    private _origBP = ACME_fnc_bpNative;
    private _nativeBP = [_patient] call _origBP;
    _nativeBP params [["_nd", 80], ["_ns", 120]];
    private _nativeMAP = _nd + ((_ns - _nd) / 3);
    private _floorMAP = missionNamespace getVariable ["ACME_circ_shockFloorMAP", 38];
    _patient setVariable ["ACME_circ_bpOffset", (-((_nativeMAP - _floorMAP) max 0)), true];

    ["Peri-arrest shock induced: immediate fluid-refractory crash.", 2.5, _medic] call ace_common_fnc_displayTextStructured;
    // the activity-log line is removed, because it revealed the condition of the patient.
};
