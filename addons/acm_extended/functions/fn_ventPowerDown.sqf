// the machine actually stops. it is called by fn_ventpaneltick when the shutdown sequence finishes.
// a ventilator has no off button for a reason: powering one down while a patient depends on it kills them. so it is
// a held action, and then it is a visible sequence, and only then does it stop. that is two chances to see what you
// are doing before it becomes irreversible.
if (!hasInterface) exitWith {};

private _tgt = uiNamespace getVariable ["ACME_vent_target", objNull];
if (isNull _tgt) exitWith {};

private _wasDriving = _tgt getVariable ["ACME_vent_driving", false];

["USER", "Ventilator powered OFF"] call ACME_fnc_ventLogbookAdd;

_tgt setVariable ["ACME_vent_driving", false, true];
_tgt setVariable ["ACME_vent_configured", false, true];
// clear the counted-breath window outright: the machine is off, so it is delivering and measuring nothing.
// it is zero rather than -1, because zero is a true reading here and -1 means no window at all, which would send the
// panel looking for a substitute number.
_tgt setVariable ["ACME_vent_measRR", 0, true];
_tgt setVariable ["ACME_vent_breathTimes", [], true];
_tgt setVariable ["ACME_vent_breathAcc", 0, true];
_tgt setVariable ["ACME_vent_alarms", [], true];
_tgt setVariable ["ACME_vent_alarmPrio", 0, true];
_tgt setVariable ["ACME_vent_alarmSilencedUntil", 0, true];

// a vent that was driving a patient was doing their breathing for them. stopping it does not hand that job back, it
// simply stops. if they cannot breathe on their own, this is the moment that starts to matter.
if (_wasDriving) then {
    // the write to ACM_breathing_BreathingEffectivenessAdjust is removed. that variable does not appear anywhere
    // in the ACM source, including under macro expansion, so nothing has ever read it and the broadcast was pure
    // network traffic.
    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_tgt, "activity", "Ventilator powered OFF while driving ventilation", "Ventilator powered off during invasive ventilation", []] call ACME_fnc_medLog;
    };
    ["VENTILATOR OFF. This patient was being ventilated by the machine.", 5] call ace_common_fnc_displayTextStructured;
} else {
    ["Ventilator powered off.", 2] call ace_common_fnc_displayTextStructured;
};

playSound "ACME_VentClick";
[87700] call ACME_fnc_minigameClose;
