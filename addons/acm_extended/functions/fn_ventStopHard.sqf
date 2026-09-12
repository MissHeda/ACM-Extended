// stop the ventilator hard, and make the operator repeat the full setup.
// two events call this function. the operator presses the power button on the reverse face, or the operator opens
// the battery hatch. both events take the power source away from the machine.
// the machine stops at once. it does not adopt the casualty again on its own. the operator repeats the whole
// first-time sequence, which is power on, boot, self test, settings and connect.
// no other stop reason calls this function. a STOP VENT, a leash break and a circuit disconnect keep their own
// behavior, because none of those removes the power.
// call it as [_reason] call ACME_fnc_ventStopHard.
//
// THE SOUND. the server sound engine in fn_postinit watches ACME_vent_driving. it plays the spool-down clip when
// that flag goes false, and it holds the next startup clip off until the spool-down ends. so this function plays
// no sound of its own.
// fn_ventdrivetick computes ACME_vent_driving from ACME_vent_connected and ACME_vent_configured on every pass.
// this function clears both of those flags before it clears the drive flag. that order stops the drive tick from
// setting the drive flag true again, which cuts the spool-down clip short.
//
// REVERT. delete this file, delete its CfgFunctions entry, and put the old bodies back in fn_ventflip at the
// power branch and the battery swap.

params [["_reason", "Ventilator stopped"]];
if (!hasInterface) exitWith {};
disableSerialization;

private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
private _tgt = uiNamespace getVariable ["ACME_vent_target", objNull];

// the power state lives on the holder, which is the casualty when a machine is connected and the medic when a
// medic carries it. fn_ventpanelopen resolves it the same way.
private _holder = uiNamespace getVariable ["ACME_vent_powerHolder", objNull];
if (isNull _holder) then { _holder = if (isNull _tgt) then { ACE_player } else { _tgt }; };

// the device state. the panel goes dark on the next frame, because fn_ventpaneltick owns the dark chrome and
// reads ACME_vent_powered.
uiNamespace setVariable ["ACME_vent_powered", false];
uiNamespace setVariable ["ACME_vent_booted", false];
uiNamespace setVariable ["ACME_vent_startScreen", ""];
ACE_player setVariable ["ACME_vent_booted", false];
// local. only this machine reads the resume screen, in fn_ventpanelopen.
ACE_player setVariable ["ACME_vent_lastScreen", "", false];
_holder setVariable ["ACME_vent_powerOn", false, true];
_holder setVariable ["ACME_vent_hasBooted", false, true];

// cancel a boot that runs now. every deferred step of fn_ventbootstart tests this stamp, so a cleared stamp
// stops the rest of the chain. hide the boot logo, because the dark-panel branch of the tick does not own it.
if ((uiNamespace getVariable ["ACME_vent_bootT0", -1]) >= 0) then {
    uiNamespace setVariable ["ACME_vent_bootT0", -1];
    if (!isNull _dlg) then {
        private _logo = _dlg displayCtrl 87760;
        if (!isNull _logo) then { _logo ctrlShow false; };
    };
};

// cancel a power-off animation that runs now. the machine stops here instead, so the animation has nothing left
// to announce. hide its caption, because that control is created at runtime and no teardown list holds it.
if ((uiNamespace getVariable ["ACME_vent_shutT0", -1]) >= 0) then {
    uiNamespace setVariable ["ACME_vent_shutT0", -1];
    private _cap = uiNamespace getVariable ["ACME_vent_shutTitle", controlNull];
    if (!isNull _cap) then { _cap ctrlShow false; };
};

if (isNull _tgt) exitWith {
    ["USER", _reason] call ACME_fnc_ventLogbookAdd;
};

private _wasDriving = _tgt getVariable ["ACME_vent_driving", false];

// the setup state goes first, and it is the part that forces the whole flow again. fn_ventpanelopen sends an
// unconfigured casualty to WEIGHT, and the tick sends the end of the self test to WEIGHT for the same reason.
[_tgt, "ACME_vent_connected", false] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_configured", false] call ACME_fnc_setVarNet;

// the machine measures nothing without power. a zero is a true reading here, and a -1 means no window at all,
// which sends the panel looking for a substitute number.
[_tgt, "ACME_vent_measRR", 0] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_breathTimes", []] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_breathAcc", 0] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_driveT0", -1] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_rrDrive", -1] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_mvAdequacy", 0] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_cpapTherapy", false] call ACME_fnc_setVarNet;

// the alarms belong to a running machine. a dead machine reports nothing.
[_tgt, "ACME_vent_alarms", []] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_alarmPrio", 0] call ACME_fnc_setVarNet;
[_tgt, "ACME_vent_alarmSilencedUntil", 0] call ACME_fnc_setVarNet;

// release the vent-driven BVM variables, and never clear a provider a medic owns. this is the same release
// fn_ventdrivetick performs on the transition, and it is repeated here because the drive flag is cleared below
// and the tick then sees no transition to act on.
// ACM reads both of these. the provider drives the injury list, in ACM's fnc_updateinjurylist, and the oxygen
// flag drives ACM's own BVM loop, in fnc_usebvm.
// fn_ventpowerdown also writes ACM_breathing_BreathingEffectivenessAdjust at this point. that variable is not in
// the ACM source at all, so no reader exists and the write is traffic only. it is left out here.
if (_wasDriving) then {
    if ((_tgt getVariable ["ACM_breathing_BVM_provider", objNull]) isEqualTo _tgt) then {
        [_tgt, [["bvmProvider", objNull], ["bvmConnectedOxygen", false]], true] call ACM_breathing_fnc_setRuntimeState;
    };
};

// the drive flag goes last, and it is the flag the sound engine watches.
[_tgt, "ACME_vent_driving", false] call ACME_fnc_setVarNet;

["USER", _reason] call ACME_fnc_ventLogbookAdd;

// a machine that was breathing for a casualty has stopped breathing for them. say so loudly, because the
// casualty is now on whatever the medic does next.
if (_wasDriving) then {
    [_tgt, "activity", "Ventilator stopped while driving ventilation", "Ventilator stopped during invasive ventilation", []] call ACME_fnc_medLog;
    ["VENTILATOR STOPPED. This patient was being ventilated by the machine.", 5] call ace_common_fnc_displayTextStructured;
};
