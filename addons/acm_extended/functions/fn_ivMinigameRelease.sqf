if ([_this,"up"] call ACME_fnc_minigameInputMouse) exitWith {true};
// MouseButtonUp. it ends the palpate and wipe hold.
// letting go part way through an insertion leaves the catheter where it is, because it is in the arm. taking hold
// again carries on from there. a stick that missed the vein is not resolved here any more: it is resolved when
// the hub seats, in fn_ivminigamesticksuccess, because the catheter goes in either way.
params ["_display", "_button"];
if (_button != 0) exitWith {false};
uiNamespace setVariable ["ACME_IV_Dragging", false];
// letting go part way through a pull leaves the catheter seated. it does not slide back out on its own.
if ((uiNamespace getVariable ["ACME_IV_PullIdx", -1]) >= 0 && {_button == 0}) then {
    [false] call ACME_fnc_ivMinigamePullStop;
};
false
