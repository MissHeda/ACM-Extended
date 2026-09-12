// the tube is through the cords. this does not finish the job: the airway is not secured until the cuff is up,
// which is the whole cost of choosing a tube over a supraglottic. it hands off to the cuff step and leaves the
// tick running. it is guarded by ACME_laryngo_tubePassed so it can only fire once, and the gag branch below is
// recoverable after the reflex problem is addressed.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
private _medic = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
if (isNull _patient) exitWith { closeDialog 0; };
private _existingTube = _patient getVariable ["ACME_ETT_Inserted", false];
if !([_medic, "intubation", _existingTube] call ACME_fnc_procedureAllowed) exitWith {};
if (uiNamespace getVariable ["ACME_laryngo_done", false]) exitWith {};
if (uiNamespace getVariable ["ACME_laryngo_tubePassed", false]) exitWith {};
uiNamespace setVariable ["ACME_laryngo_tubePassed", true];

// A graded response replaces the former all-or-nothing sedation threshold.
// Arousal from repeated instrumentation can overcome partial suppression; true
// paralysis, arrest and absent reflexes remain hard exclusions in the shared reader.
private _misses = _patient getVariable ["ACME_laryngo_gagMisses", 0];
private _gagChance = [_patient, 1 + (_misses max 0) * 0.4] call ACME_fnc_laryngoReflexChance;
if (random 1 < _gagChance) exitWith {
    uiNamespace setVariable ["ACME_laryngo_done", true];
    // fail: the patient gags on the tube. do not secure the airway.
    if (!isNull _dlg) then {
        (_dlg displayCtrl 87810) ctrlSetText "Patient gagged on the blade.";
    };
    // OPA dislodgement only follows a real, owner-approved emesis event.
    [_patient, "gag"] call ACME_fnc_laryngoFail;
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_patient, "airway",
 "Intubation attempt stopped after gagging",
 "Intubation attempt stopped, gag reflex",
 []] call ACME_fnc_medLog;
    };
    // hand the screen back after a beat, so the gag message is read before the panel goes live again. the reset
    // mirrors fn_laryngoabort: back to the start of the attempt with the scope still in hand if it was held.
    // the tube is not consumed on this path, because the removeitem below is never reached, so it is still theirs
    // to place once the airway is clear.
    [{
        params ["_oldDisplay", "_oldPatient"];
        if (isNull _oldDisplay || {_oldDisplay != (uiNamespace getVariable ["ACME_laryngo_dlg", displayNull])}
            || {_oldPatient != (uiNamespace getVariable ["ACME_laryngo_patient", objNull])}) exitWith {};
        uiNamespace setVariable ["ACME_laryngo_done", false];
        uiNamespace setVariable ["ACME_laryngo_tubePassed", false];
        // the tube comes out.
        // the reset cleared the depth and left the tube in the hand, so it stayed drawn on screen at depth zero. that
        // was survivable until the blade became required to move a tube: after a failure the blade is out, so the tube
        // could not be moved at all and simply sat there.
        // a failed attempt ends with the tube out of the airway and back in the tray, which is what happens in life.
        // it is not consumed, so it can be picked up and used again.
        // the scope is left alone. if it was in the hand it stays there, because the medic has not put it down.
        if ((uiNamespace getVariable ["ACME_laryngo_held", ""]) == "tube") then {
            uiNamespace setVariable ["ACME_laryngo_held", ""];
        };
        uiNamespace setVariable ["ACME_laryngo_tubeInHand", false];
        uiNamespace setVariable ["ACME_laryngo_tubeGrip", false];
        uiNamespace setVariable ["ACME_laryngo_tubeImpulse", 0];
    uiNamespace setVariable ["ACME_laryngo_tubeStep", 0];
        call ACME_fnc_laryngoRefreshSlots;
        uiNamespace setVariable ["ACME_laryngo_state",
            (if ((uiNamespace getVariable ["ACME_laryngo_held", ""]) == "scope") then {"scopeHeld"} else {"idle"})];
        uiNamespace setVariable ["ACME_laryngo_holding", false];
        uiNamespace setVariable ["ACME_laryngo_regripHeld", false];
        uiNamespace setVariable ["ACME_laryngo_gripStr", 0];
        uiNamespace setVariable ["ACME_laryngo_airwayOpen", false];
        uiNamespace setVariable ["ACME_laryngo_lift", 0];
        uiNamespace setVariable ["ACME_laryngo_liftPending", 0];
        uiNamespace setVariable ["ACME_laryngo_overPressure", 0];
        uiNamespace setVariable ["ACME_laryngo_reveal", 0];
    }, [_dlg, _patient], 0.6] call CBA_fnc_waitAndExecute;
};

[_patient, "success"] call ACME_fnc_laryngoConsequence;
// Through the cords; cuff and securement still require completion.
// the tube is committed. it is through the cords, so it stops being a thing in your hand and comes off the count,
// because it belongs to the patient now. it keeps drawing seated and is simply not carried any more.
private _med = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
if (!isNull _med && {!_existingTube}) then { _med removeItem "ACME_ETTube"; };
uiNamespace setVariable ["ACME_laryngo_tubeInHand", false];
uiNamespace setVariable ["ACME_laryngo_tubeGrip", false];
uiNamespace setVariable ["ACME_laryngo_tubeAnchored", false];
uiNamespace setVariable ["ACME_laryngo_held", ""];
// freshly through the cords, so it is fully seated. migration measures from here.
private _pt0 = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (!isNull _pt0) then {
    [_pt0, "placement", [1]] call ACME_fnc_ettMigrationStateCommit;
    [_pt0, "obstruction", [false]] call ACME_fnc_ettMigrationStateCommit;
};
// where it ended up, and whether that is too deep. past the ideal frame of this casualty the tube is down the right
// main bronchus, so one lung gets the whole tidal volume and the other gets nothing.
// the trap is that the capnograph still looks fine, because the tube is in the trachea and CO2 is coming back. it
// is the saturation and the airway pressure that give it away, and later the chest that sounds wrong on one side.
// that is exactly the diagnostic problem worth training.
private _pt1 = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
private _frameNow = 1 + (round ((uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0]) * 7));
private _idealF = uiNamespace getVariable ["ACME_laryngo_idealFrame", 8];
if (!isNull _pt1) then {
    private _deep = _frameNow > _idealF;
    [_pt1, "placement", ["__KEEP__", _frameNow, _deep]] call ACME_fnc_ettMigrationStateCommit;
    if (_deep) then {
        [_pt1, "airway", "ET tube advanced into the right main bronchus", "R mainstem intubation", []] call ACME_fnc_medLog;
    };
};
uiNamespace setVariable ["ACME_laryngo_state", "seated"];
[] call ACME_fnc_laryngoRefreshSlots;
uiNamespace setVariable ["ACME_laryngo_holding", false];
if (!isNull _dlg) then {
    [_dlg, 1] call ACME_fnc_laryngoTubeFrames;
    // seated. the swing stops and the tube hangs straight, held by the airway rather than by your fingers.
    uiNamespace setVariable ["ACME_laryngo_tubeAng", 0];
    uiNamespace setVariable ["ACME_laryngo_tubeAngVel", 0];
    private _tp = uiNamespace getVariable ["ACME_laryngo_tubeTipPos", []];
    if ((count _tp) >= 2) then {
        [_dlg, _tp select 0, _tp select 1, 0] call ACME_fnc_laryngoTubePose;
        // remember where it ended up, as a fraction of the frame rather than as screen coordinates.
        // fn_laryngoclose clears the screen-space copy, and it has to: those coordinates only mean anything for the
        // layout that produced them, and the next open can be a different resolution or aspect. storing the
        // fraction on the patient keeps the one fact that survives, which is where in the airway the tube sits.
        // the reopen in fn_laryngoinit reads this back, so a secured tube is redrawn exactly where the medic left
        // it rather than at an anchor that only approximates it.
        (uiNamespace getVariable ["ACME_laryngo_frame", [0,0,1,1]]) params ["_ffx","_ffy","_ffw","_ffh"];
        if (_ffw > 0 && {_ffh > 0}) then {
            _patient setVariable ["ACME_ETT_TipFrac",
                [(((_tp select 0) - _ffx) / _ffw), (((_tp select 1) - _ffy) / _ffh)], true];
        };
    };
};
playSound "ACME_VentClick";

// B39: if the operator inflated the cuff before seating, crossing the cords now converts that
// mechanical cuff state into a definitive airway without forcing them to repeat the syringe step.
if (uiNamespace getVariable ["ACME_laryngo_cuffDone", false]) then {
    [] call ACME_fnc_laryngoCuffDone;
};
