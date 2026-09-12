// open the megacode control panel for a dummy and play the radio-talk sequence of the operator:
// Acts_Kore_TalkingOverRadio_in, then _loop, held while the panel is open. _out plays on close.
// _this is [_target], the megacode dummy, and [_player], the operator, from the ACE interaction.
params ["_target", ["_caller", objNull]];
if (isNull _target) exitWith {};
if (isNull _caller) then { _caller = ACE_player; };

uiNamespace setVariable ["ACME_MC_target", _target];
uiNamespace setVariable ["ACME_MC_operator", _caller];
// publish the operator on the manikin, so the server-side death handler can toast and log to the right client.
_target setVariable ["ACME_MC_operatorClient", _caller, true];

// the radio-talk gesture chain on the operator. a token lets the close handler, or a superseding open, cancel a
// pending in-into-loop hand-off so it cannot fire after the panel has been shut.
private _tok = (_caller getVariable ["ACME_MC_animTok", 0]) + 1;
_caller setVariable ["ACME_MC_animTok", _tok, false];
[_caller, "Acts_Kore_TalkingOverRadio_in"] call ACME_fnc_doAnim;
[{
    params ["_op", "_t"];
    if (isNull _op) exitWith {};
    if ((_op getVariable ["ACME_MC_animTok", -1]) != _t) exitWith {};  // superseded / panel closed
    if (isNull (uiNamespace getVariable ["ACME_Megacode_DLG", displayNull])) exitWith {};
    [_op, "Acts_Kore_TalkingOverRadio_loop"] call ACME_fnc_doAnim;
}, [_caller, _tok], missionNamespace getVariable ["ACME_megacode_animInTime", 1.6]] call CBA_fnc_waitAndExecute;

createDialog "ACME_Megacode_Panel";
