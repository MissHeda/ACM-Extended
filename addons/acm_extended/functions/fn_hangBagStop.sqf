// tear down hang bag locally. it is safe to call repeatedly.
// on cancel we play the lower-the-bag exit animation and keep the bag and iv line in hand until it finishes, then
// delete them and restore the weapon, so the bag visibly comes down instead of popping out of existence.
params [["_silent", false]];
private _medic = ACE_player;
if !(_medic getVariable ["ACME_hang_Active", false]) exitWith {};

private _patient = _medic getVariable ["ACME_hang_Patient", objNull];

// Retire the held-loop generation before starting the authored exit. Otherwise fn_doAnimHeld can reassert the
// static hold after RMB/Escape and leave the player frozen/sliding in a standing animation.
if (local _medic) then { [_medic, ""] call ACME_fnc_doAnimHeld; };
_medic setVariable ["ACME_hang_Active", false, true];

// immediate: stop all the per-frame machinery and the cancel prompt.
[_medic, false] call ACME_fnc_hangBagInputLock;
[false] call ACME_fnc_hangBagHint;

private _pfh = _medic getVariable ["ACME_hang_PFH", -1];
if (_pfh >= 0) then { [_pfh] call CBA_fnc_removePerFrameHandler; };
_medic setVariable ["ACME_hang_PFH", -1];

{ [_x, "keydown"] call CBA_fnc_removeKeyHandler; } forEach (_medic getVariable ["ACME_hang_KeyIDs", []]);
_medic setVariable ["ACME_hang_KeyIDs", []];

// capture the props, so the delayed teardown can delete them after the exit animation.
private _rope      = _medic getVariable ["ACME_hang_Rope", objNull];
private _anchor    = _medic getVariable ["ACME_hang_LineAnchor", objNull];
private _bagHelper = _medic getVariable ["ACME_hang_BagHelper", objNull];
private _bag       = _medic getVariable ["ACME_hang_Bag", objNull];

private _outAnim = missionNamespace getVariable ["ACME_hang_outAnim", "ACME_Acts_JetsCrewaidFCrouchThumbup_out"];
private _outTime = missionNamespace getVariable ["ACME_hang_outTime", 1.00];
private _playedOut = false;
if (local _medic && {(toLower animationState _medic) find "jetscrewaidfcrouchthumbup" >= 0}) then {
    // Exit through the authored lower-the-bag state at ACE priority 1/playMoveNow so its interpolateTo path
    // remains visible instead of falling back to a hard switchMove.
    [_medic, _outAnim, 1] call ACME_fnc_doAnim;
    _playedOut = true;
};

// delayed: after the exit animation, drop the bag and line and re-arm.
private _teardown = {
    params ["_medic", "_rope", "_anchor", "_bagHelper", "_bag", "_playedOut"];
    if (!isNull _rope) then { [_rope] call ACME_fnc_ivLineDestroy; };
    if (!isNull _bagHelper) then { detach _bagHelper; deleteVehicle _bagHelper; };
    if (!isNull _anchor) then { detach _anchor; deleteVehicle _anchor; };
    if (!isNull _bag) then { detach _bag; deleteVehicle _bag; };
    if (local _medic) then {
        _medic enableAI "ANIM";
        // always hand control back to a normal movable idle. the exit state is static and no-control, and its interpolateto
        // cannot be relied on to fire. if we do not reset here the medic stays frozen in the lower pose, with the bag
        // already gone, and can do nothing. resetting after the exit has played avoids that.
        // retire any hold loop still pushing a pose on this medic. an empty animation takes the next generation in
        // fn_doanimheld and starts nothing, which is the only way to make an older loop stand down. without it the
        // loop keeps re-asserting its pose after the release and the medic stays stuck in it.
        // Hand movement back to a known crouch through the move graph. The old empty priority-2 reset could
        // visibly snap at the exact frame the bag disappeared.
        [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;
        private _savedSlots = _medic getVariable ["ACME_hang_savedWeaponSlots", []];
        if !(_savedSlots isEqualTo []) then {
            // restore the removed back weapons, with their attachments and loaded mags. re-read the current loadout and only
            // swap the two weapon slots back, so any inventory change during the hold is preserved.
            private _ld = getUnitLoadout _medic;
            _ld set [0, _savedSlots select 0];
            _ld set [1, _savedSlots select 1];
            _medic setUnitLoadout _ld;
            _medic setVariable ["ACME_hang_savedWeaponSlots", nil];
        };
        _medic selectWeapon "";
        _medic setUnitPos "MIDDLE";
    };
};
[_teardown, [_medic, _rope, _anchor, _bagHelper, _bag, _playedOut], (if (_playedOut) then {_outTime} else {0})] call CBA_fnc_waitAndExecute;

// clear the references and the state now. the delayed block holds its own copies.
_medic setVariable ["ACME_hang_Rope", objNull];
_medic setVariable ["ACME_hang_LineAnchor", objNull];
_medic setVariable ["ACME_hang_BagHelper", objNull];
_medic setVariable ["ACME_hang_Bag", objNull];
_medic setVariable ["ACME_hang_RopeShown", false, true];
_medic setVariable ["ACME_hang_Pose", nil];
_medic setVariable ["ACME_hang_PoseRetryAt", nil];
_medic setVariable ["ACME_hang_Raising", false];

if (!isNull _patient) then {
    _patient setVariable ["ACME_hang_flowMult", 1, true];
    _patient setVariable ["ACME_hang_Medic", objNull, true];
};
if (!_silent) then {
    ["IV bag lowered.", 2, _medic] call ace_common_fnc_displayTextStructured;
    // canceling the hang returns the medic straight to the transfusion menu they came from, with no weapon-raise and
    // no dead air. it is delayed until just after the lower-the-bag exit animation has played, so it is not cut
    // short.
    if (!isNull _patient) then {
        private _bp = _medic getVariable ["ACME_hang_Part", missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""]];
        private _reopenDelay = (if (_playedOut) then {_outTime} else {0}) + 0.10;
        [{
            params ["_medic", "_patient", "_bp"];
            if (isNull _medic || {isNull _patient}) exitWith {};
            if !(_medic getVariable ["ACME_hang_Active", false]) then {
                [_medic, _patient, _bp] call ACM_circulation_fnc_openTransfusionMenu;
            };
        }, [_medic, _patient, _bp], _reopenDelay] call CBA_fnc_waitAndExecute;
    };
};
