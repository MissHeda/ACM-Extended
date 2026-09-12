uiNamespace setVariable ["ACME_RollerClamp_Dragging", false];
private _return = uiNamespace getVariable ["ACME_RollerClamp_Return", []];

// close the clamp dialog, 86200, explicitly by its handle. closedialog closes whatever the engine treats as the
// topmost user dialog, which is not guaranteed to be the clamp, so we target the handle directly. onunload still
// fires and resets the own ui state of the clamp.
private _clamp = findDisplay 86200;
if (!isNull _clamp) then { _clamp closeDisplay 2; } else { closeDialog 0; };

// critical: do not reopen the menu in the same or the next frame. issuing a fresh dialog open while the closedisplay
// of the clamp is still settling cancels the close, leaving the clamp dialog alive underneath the reopened menu.
// the layout pfh then bails on its skip-while-clamp-is-open guard every frame and the menu stays frozen at its raw
// config positions. that is the scrambled menu after give infusion, titrate and done report, proven by the layout
// dump showing clamp 86200 still open 1.5 s after done.
// instead, wait until the clamp display is actually gone, then reopen the menu if opening the clamp had taken it
// down. the layout pfh then lays out cleanly.
if (!(_return isEqualTo [])) then {
    uiNamespace setVariable ["ACME_RollerClamp_ReopenDeadline", diag_tickTime + 2];
    [
        { (isNull (findDisplay 86200)) || {diag_tickTime > (uiNamespace getVariable ["ACME_RollerClamp_ReopenDeadline", 0])} },
        {
            params ["_ret"];
            if (isNull (findDisplay 86000)) then {
                [ACM_circulation_fnc_openTransfusionMenu, _ret] call CBA_fnc_execNextFrame;
            };
        },
        [_return]
    ] call CBA_fnc_waitUntilAndExecute;
};
