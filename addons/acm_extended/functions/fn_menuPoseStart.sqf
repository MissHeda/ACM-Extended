/* Medical-menu provider stance.
 *
 * Opening another person's medical menu does not start a medic-over-patient animation. Those states can own
 * root/head motion, which caused sideways drift and forced the player's view downward. The menu does exactly
 * one thing for theatre: it moves the local provider into the kneel for the weapon in hand. The weapon stays.
 * No loop, no held RTM, no switchMove and no head/aim lock are used.
 *
 * The tiny state record exists only so menu Unload/new-menu calls can retire the request safely. Treatment poses
 * are still allowed to replace it immediately.
 */
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_display", displayNull, [displayNull]]];
if !(missionNamespace getVariable ["ACME_menuPoseEnabled", true]) exitWith {false};
if (isNull _medic || {!local _medic} || {!alive _medic} || {_medic getVariable ["ACE_isUnconscious", false]}) exitWith {false};
if (isNull _patient || {_patient isEqualTo _medic} || {!(_patient isKindOf "CAManBase")}) exitWith {false};
if ([_medic] call ACME_fnc_animBlocked || {!isNull objectParent _patient}) exitWith {false};
// ACE reopens the medical menu on the frame after a treatment succeeds. The head-elevation lift starts on that
// same frame, so the reopen used to replace the lift with a kneel and the lift was never seen. The lift owns the
// provider until it is complete.
if (_medic getVariable ["ACME_headElev_seqActive", false]) exitWith {false};
if (isNull _display) then {_display = uiNamespace getVariable ["ace_medical_gui_menuDisplay", displayNull];};
if (isNull _display) exitWith {false};

[_medic, true] call ACME_fnc_menuPoseStop;

private _epoch = (_medic getVariable ["ACME_menuPoseEpoch", 0]) + 1;
_medic setVariable ["ACME_menuPoseEpoch", _epoch];
_medic setVariable ["ACME_menuPose", [_epoch, _display, _patient]];

// The menu does not stow the weapon. The provider goes to the kneel for the weapon in hand through the move graph,
// which is the ACE goKneeling method. A treatment that needs empty hands stows the weapon in its own preflight,
// see overrides/fn_treatment.sqf. Head positioning also enforces empty hands in fn_headElevMedicSeq.
if (_medic call ace_common_fnc_isSwimming) exitWith {true};
_medic setUnitPos "MIDDLE";
if (stance _medic != "CROUCH") then {
    private _kneel = ["AmovPknlMstpSnonWnonDnon", "AmovPknlMstpSlowWrflDnon", "AmovPknlMstpSrasWlnrDnon",
        "AmovPknlMstpSlowWpstDnon", "AmovPknlMstpSoptWbinDnon"]
        select ((["", primaryWeapon _medic, secondaryWeapon _medic, handgunWeapon _medic, binocular _medic] find currentWeapon _medic) max 0);
    [_medic, _kneel, 0] call ACME_fnc_doAnim;
};
true
