// the onunload for the megacode control panel. it stops the live monitor pfh and plays the radio-talk _out of the
// operator, then releases the gesture so they return to a normal stance.
params [["_display", displayNull]];

private _pfh = uiNamespace getVariable ["ACME_MC_tickPFH", -1];
if (_pfh >= 0) then { [_pfh] call CBA_fnc_removePerFrameHandler; };
uiNamespace setVariable ["ACME_MC_tickPFH", -1];
uiNamespace setVariable ["ACME_Megacode_DLG", displayNull];

private _op = uiNamespace getVariable ["ACME_MC_operator", objNull];
if (!isNull _op) then {
    // invalidate any pending in-into-loop hand-off, then play out and hard-release. the release is unconditional,
    // because the old state-gated version could miss and leave the player stuck in the full-body radio animation, only
    // able to turn in place. switchmove "" plus setUnitPos AUTO restores control.
    _op setVariable ["ACME_MC_animTok", (_op getVariable ["ACME_MC_animTok", 0]) + 1, false];
    [_op, "Acts_Kore_TalkingOverRadio_out"] call ACME_fnc_doAnim;
    [{
        params ["_o"];
        if (isNull _o) exitWith {};
        if !([_o] call ACME_fnc_animBlocked) then {
            ["ace_common_switchMove", [_o, ""]] call CBA_fnc_globalEvent;
        };
        _o setUnitPos "AUTO";
    }, [_op], missionNamespace getVariable ["ACME_megacode_animOutTime", 1.4]] call CBA_fnc_waitAndExecute;
};
