// open the ventilator control panel. there are three entry modes.
// self-interaction, in preset mode, from [] or [objnull, true]. the medic presets settings on their own carried
// ventilator, such as a flight medic dialling in the weight, mode and settings from the 9-line of the ground
// medic before reaching the patient. the target is the medic. after a preset open, the boot sequence is skipped
// on subsequent opens, because the device is already powered and configured, until the ventilator item is
// reloaded, transferred out or otherwise moved. see fn_ventinvreset, which re-arms boot.
// the patient medical menu, under advanced treatments, from [_patient]. it opens the panel bound to that
// patient, so the running vent drives the ventilation of that patient. boot plays on the first open of a fresh
// device.
// a legacy self open with no args behaves as preset-on-self.
// the args are 0 for the target, an object defaulting to ACE_player, and 1 for presetmode, a bool defaulting to
// whether the target is self.
// there is one ventilator. both entry points open the same device, on the same patient, showing the same state.
// this used to be two machines. the self-interaction opened a preset ventilator bound to ace_player, the medic,
// so the medic became a ventilated patient in their own right. walk that through the setup flow and you have
// connected an invasive circuit to your own chest with no tube in it, which is a circuit disconnect alarm,
// screaming at you, at the same time as the alarms of the real casualty. two vents, two patients and two alarm
// patterns at once. the machine was never meant to be two machines.
// now the device remembers which casualty it is connected to, in ACME_vent_devicePatient, held on the medic. the
// patient button connects it and opens it, and the self-interaction opens the same thing again. either one shows
// the state of the other, because there is no other state.
params [["_target", objNull], ["_presetMode", false]];
if (!hasInterface) exitWith {};
if !([ACE_player, "ventilator", true] call ACME_fnc_procedureAllowed) exitWith {};
if (!isNull _target && {_target isNotEqualTo ACE_player} && {(!alive _target) || {_target getVariable ["ACME_vent_recovering", false]}}) exitWith {
    ["This ventilator is being recovered from the patient.", 3] call ace_common_fnc_displayTextStructured;
};

// a machine already affixed to this casualty is reachable without carrying one, because connecting it is what
// removed it from the kit of the medic in the first place. carrying a spare still opens it preset-style.
private _affixed = (!isNull _target) && {_target getVariable ["ACME_vent_onPatient", false]};
if (!_affixed && {([ACE_player, "ACME_Ventilator"] call ace_common_fnc_getCountOfItem) < 1}) exitWith {
    ["No ventilator in your kit.", 2] call ace_common_fnc_displayTextStructured;
};

private _self = (isNull _target) || {_target isEqualTo ACE_player};
private _presetMode = false;

if (_self) then {
    // the self-interaction shows whatever casualty this device is already on.
    _target = ACE_player getVariable ["ACME_vent_devicePatient", objNull];
};

// preset mode. there is no patient yet, so you are configuring the machine: the weight, mode, interface and
// params, dialled in on the ground before you ever reach the casualty. that is a real workflow.
// the distinction that makes it safe is this.
// configured means the machine has settings on it. that is harmless on the medic, and it is presetting.
// connected means a circuit is attached to a chest. that is only ever true on a real casualty.
// the drive and alarm ticks require both. the old bug was that presetting could walk you through the connect
// screen and set connected to true on the medic, which made you a ventilated patient with an open circuit and no
// tube, and started screaming circuit disconnect at you. so configure freely and connect never.
if (isNull _target || {!alive _target}) then {
    _target = ACE_player;
    _presetMode = true;
};

if (_presetMode) then {
    // belt and braces. the device owner can never be connected, and can never sit in the circulation loop.
    ACE_player setVariable ["ACME_vent_connected", false, true];
    ACE_player setVariable ["ACME_vent_driving", false, true];
    ACE_player setVariable ["ACME_vent_alarms", [], true];
    if (!isNil "ACME_circ_activePatients") then {
        ACME_circ_activePatients = ACME_circ_activePatients - [ACE_player];
    };
} else {
    // opening it on a casualty is what binds the device to them.
    ACE_player setVariable ["ACME_vent_devicePatient", _target, true];

    // carry your presets across to the patient, and only if this patient has not been set up yet. if you dialled the
    // machine in on the ground, that work should still be there when you kneel down.
    if (!(_target getVariable ["ACME_vent_configured", false]) && {(_target getVariable ["ACME_vent_custodyId", ""]) == ""}) then {
        {
            private _v = ACE_player getVariable [_x, nil];
            if (!isNil "_v") then { _target setVariable [_x, _v, true]; };
        } forEach ["ACME_vent_weight","ACME_vent_mode","ACME_vent_iface","ACME_vent_bpm","ACME_vent_vt",
                   "ACME_vent_pinsp","ACME_vent_psup","ACME_vent_trigSensCmH2O",
                   "ACME_vent_fio2","ACME_vent_peep","ACME_vent_ie","ACME_vent_alertRRLow","ACME_vent_alertRRHigh",
                   "ACME_vent_alertPLimit","ACME_vent_alertPAlert","ACME_vent_alertInvIE",
                   "ACME_vent_alertMVlowLpm","ACME_vent_alertMVhighLpm"];
    };
};

// bind the panel to its target: a casualty, or the machine itself when presetting.
uiNamespace setVariable ["ACME_vent_target", _target];
uiNamespace setVariable ["ACME_vent_presetMode", _presetMode];

// where do we open? pick up where you left off, unless the patient is not set up yet.
// a fresh casualty always goes to WEIGHT. you are not getting a mode chosen for you: weight, then mode, then
// params.
// otherwise it goes to the screen you were last on, so reopening resumes rather than restarting.
private _resume = ACE_player getVariable ["ACME_vent_lastScreen", ""];
private _startScreen = "";
if (!_presetMode && {!(_target getVariable ["ACME_vent_configured", false])}) then {
    _startScreen = "weight";
} else {
    if (_resume != "" && {!(_resume in ["boot","selftest"])}) then { _startScreen = _resume; };
};
uiNamespace setVariable ["ACME_vent_startScreen", _startScreen];

// opening the panel is not switching the machine on. looking at a device does not power it, and a ventilator
// that boots itself the moment someone glances at it cannot be deliberately left off. the power state lives on
// the machine and persists across opens. it starts off, and the only things that change it are the power button
// on the back and fitting a fresh battery.
// it is stored on the same holder the battery charge uses, which is the casualty when one is connected and the
// medic when the machine is being carried, so a device handed between medics keeps its state.
// on the boot gating: boot plays on the first open of a given ventilator item and again after a new patient
// reset. a preset open, through the self-interaction, counts as powering the device on, so once you have preset
// it, subsequent opens skip boot until the item is moved or reloaded, because fn_ventinvreset clears the boot
// flag. if the target is already configured, such as a patient just connected through "Connect ET >
// Ventilator", boot is skipped regardless and it opens straight to the live screen, so open ventilator on a
// connected patient behaves like reopening a configured self-preset device.
private _pwrHolder = if (_target isEqualTo ACE_player) then { ACE_player } else { _target };
private _wasOn = _pwrHolder getVariable ["ACME_vent_powerOn", false];
uiNamespace setVariable ["ACME_vent_powered", _wasOn];
uiNamespace setVariable ["ACME_vent_powerHolder", _pwrHolder];

// boot only runs when the machine is actually on and has not already booted. a device left running keeps
// running, and reopening the panel on it goes straight to the screen it was showing.
// the boot state belongs to the machine. it was tracked on the player, so anything that cleared that flag, or any
// second device, made a running ventilator boot again the next time its panel was opened. a machine that is on
// and has finished starting stays started, and reopening the panel is looking at it rather than switching it on.
// it is set false by the power button and by pulling the battery, which are the only two things that actually
// stop it.
private _hasBooted = _pwrHolder getVariable ["ACME_vent_hasBooted", false];
private _targetConfigured = _target getVariable ["ACME_vent_configured", false];
uiNamespace setVariable ["ACME_vent_doBoot", _wasOn && {!_hasBooted} && {!_targetConfigured}];
if (_wasOn && {!_hasBooted}) then { _pwrHolder setVariable ["ACME_vent_hasBooted", true, true]; };

// the self-interaction opens immediately, because that path has always worked. the patient path is launched from
// a medical-menu treatment, after which ACE closes the menu through closedialog, which would close this dialog
// too. so that open is deferred past ACE's cleanup, exactly like the intubation mini-game. the _target check
// runs here, in this scope where _target is defined, and only the createdialog is deferred. the deferred block
// must not reference _target, or it evaluates as nil in the scheduled scope and the open silently fails.
// THE OPEN VERIFIES ITSELF, BECAUSE IN A VEHICLE IT WAS NOT TAKING.
// the patient path is deferred past ACE's own cleanup, because ACE closes the medical menu with closeDialog after
// callbackSuccess has run and that would take our dialog with it. the delay was a fixed 0.1 s, which is a race
// against ACE's timing rather than a wait for it.
// inside a vehicle that race is lost. the panel opened and shut again in the same breath, which is what a
// closeDialog arriving a moment too late looks like from the outside.
// so rather than guess at a longer number, the open checks whether it took and repeats it once if it did not.
// one retry, never a loop: if the second attempt is closed as well, something other than the cleanup is doing it
// and hammering createDialog would only make that harder to see.
private _fnOpen = {
    if !([ACE_player, "ventilator", true] call ACME_fnc_procedureAllowed) exitWith {};
    createDialog "ACME_Ventilator_Dialog";
    [{
        if (!isNull (findDisplay 87700)) exitWith {};
        if !([ACE_player, "ventilator", true] call ACME_fnc_procedureAllowed) exitWith {};
        createDialog "ACME_Ventilator_Dialog";
    }, [], (missionNamespace getVariable ["ACME_vent_openRetrySec", 0.35])] call CBA_fnc_waitAndExecute;
};

if (_target isEqualTo ACE_player) then {
    call _fnOpen;
} else {
    [_fnOpen, [], 0.1] call CBA_fnc_waitAndExecute;
};
