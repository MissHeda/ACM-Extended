// the laryngoscope and the flashlight are the same light.
// ["grab"] call ACME_fnc_laryngoFlash means the scope is now in hand.
// ["stow"] call ACME_fnc_laryngoFlash means the scope has been put down.
// ["blocked"] call ACME_fnc_laryngoFlash returns true if the self-interaction should be hidden.
// a medic has one pair of hands and one light. holding a lit laryngoscope and separately switching a torch on and
// off is two lights, which is one more than exists. so the scope drives the ACE flashlight directly rather than
// adding a second light source alongside it.
// the rule that makes this subtle is that whoever turned the light on owns it.
// if the light was off when the scope came out, the scope turns it on and turns it off again when stowed.
// if the light was already on, the scope leaves it completely alone, during and after. the medic had a torch
// running before they reached for the blade and it is still their torch, and nothing the scope does should take
// it away.
// without that distinction, picking the scope up and putting it down again silently extinguishes a torch the medic
// was already using, which is the kind of thing that is only noticed at night in the middle of something.
// ACE stores the current light as ace_map_flashlight, which is [classname, glowobject], on the unit, so the state
// is read straight from ACE rather than tracked separately. there is no second source of truth to drift.

params [["_mode", ""]];
if (!hasInterface) exitWith { false };

#define OWNER_VAR "ACME_laryngo_lightOwned"
#define WAS_VAR   "ACME_laryngo_lightWas"

private _current = {
    (ACE_player getVariable ["ace_map_flashlight", ["", objNull]]) select 0
};

if (_mode isEqualTo "grab") exitWith {
    private _on = call _current;

    if (_on != "") exitWith {
        // already lit, and not by us, so hands off. it is recorded, so the stow path knows to leave it running.
        uiNamespace setVariable [OWNER_VAR, false];
        uiNamespace setVariable [WAS_VAR, _on];
        false
    };

    // dark. the scope brings its own light up, after a beat.
    // the delay is not cosmetic. a real laryngoscope lights when the blade is unfolded and latched, which is a
    // physical action that takes a moment. it also stops the light strobing if a medic clicks the tray twice while
    // deciding, because the callback re-checks that the scope is still held before doing anything.
    uiNamespace setVariable [OWNER_VAR, true];
    uiNamespace setVariable [WAS_VAR, ""];

    private _pick = missionNamespace getVariable ["ACME_laryngo_flashClass", ""];
    if (_pick isEqualTo "") then {
        // whatever torch the medic is actually carrying, so the beam and the color are theirs rather than a generic one
        // bolted on. it falls back to the standard issue light if they have none, because the blade has its own lamp and
        // does not depend on the medic owning a torch.
        private _own = [ACE_player] call ace_map_fnc_getUnitFlashlights;
        _pick = if (_own isEqualTo []) then { "ACE_Flashlight_MX991" } else { _own select 0 };
    };

    [{
        params ["_cls"];
        // re-checked, because the medic may have put the scope down again inside the delay.
        if ((uiNamespace getVariable ["ACME_laryngo_held", ""]) != "scope") exitWith {};
        if !(uiNamespace getVariable [OWNER_VAR, false]) exitWith {};
        [ACE_player, _cls] call ace_map_fnc_switchFlashlight;
    }, [_pick], (missionNamespace getVariable ["ACME_laryngo_flashDelay", 0.6])] call CBA_fnc_waitAndExecute;

    true
};

if (_mode isEqualTo "stow") exitWith {
    // instant, unlike the switch on. putting the blade down folds it, and a folded blade is dark immediately. there is
    // also no reason to make someone wait to go dark, which is usually why they are putting it away.
    if (uiNamespace getVariable [OWNER_VAR, false]) then {
        [ACE_player, ""] call ace_map_fnc_switchFlashlight;
    };
    // if we did not own it, this branch does nothing at all and the torch of the medic keeps running.
    uiNamespace setVariable [OWNER_VAR, false];
    uiNamespace setVariable [WAS_VAR, ""];
    true
};

if (_mode isEqualTo "blocked") exitWith {
    // one light at a time. while the scope is in hand the flashlight self-interaction is hidden, so the medic cannot
    // switch to a torch they are not holding and cannot turn off a light the scope is currently using. put the scope
    // down and the entry comes straight back.
    (!isNull (findDisplay 87800)) && {(uiNamespace getVariable ["ACME_laryngo_held", ""]) isEqualTo "scope"}
};

false
