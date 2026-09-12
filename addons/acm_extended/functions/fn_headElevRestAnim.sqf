// Give the pose the casualty returns to after the head is lowered.
// Call it as [_patient] call ACME_fnc_headElevRestAnim. It returns a state name.
// fn_headElevateStart stores the pose the casualty had before the lift in ACME_headElev_baseAnim.
// An unconscious casualty has an ACE unconscious pose. A treated casualty has ACM_LyingState.
// The stored pose is used only when it is a resting pose. A transition pose, or an ACME pose, is never replayed.
// When the stored pose is not a resting pose, the global ACME_headElev_restAnim is used.
params [["_patient", objNull, [objNull]]];
private _rest = missionNamespace getVariable ["ACME_headElev_restAnim", "ACM_LyingState"];
if (!(_rest isEqualType "")) then {_rest = "ACM_LyingState";};
if (isNull _patient) exitWith {_rest};

private _base = _patient getVariable ["ACME_headElev_baseAnim", ""];
if (!(_base isEqualType "") || {_base == ""}) exitWith {_rest};
private _lower = toLower _base;

// Only an unconscious pose or the ACM lying pose is restored. A BI injured prone idle is a conscious pose and
// makes an unconscious casualty look awake, so it is never restored.
private _resting = (_lower in ["unconscious", "acm_lyingstate"])
    || {(_lower find "ace_medical_engine_uncon_anim_") == 0};
if (!_resting) exitWith {_rest};
if (!isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _base)) exitWith {_rest};
_base
