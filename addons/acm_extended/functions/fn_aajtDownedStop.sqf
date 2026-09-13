/* NA4: machine-local AAJT worker teardown, including reset and locality loss.
   Never clear another owner's clinical device flags or an obtunded input lock. */
params ["_patient"];
if (isNull _patient) exitWith {};
private _h = _patient getVariable ["ACME_AAJT_downedPFH", -1];
if (_h >= 0) then {[_h] call CBA_fnc_removePerFrameHandler;};
_patient setVariable ["ACME_AAJT_downedPFH", -1, false];
_patient setVariable ["ACME_AAJT_downedActive", false, false];
_patient setVariable ["ACME_AAJT_uprightSince", -1, false];
_patient setVariable ["ACME_AAJT_treatmentGraceUntil", -1, false];
private _locked = _patient getVariable ["ACME_AAJT_lockOn", false];
_patient setVariable ["ACME_AAJT_lockOn", false, false];
if (_locked && {hasInterface} && {_patient isEqualTo ACE_player}
    && {!(_patient getVariable ["ACME_obtunded", false])}) then {
    [_patient, false] call ACME_fnc_obtundedInputLock;
};
if (local _patient && {alive _patient} && {_patient getVariable ["ACME_AAJT_collapseOwned", false]}
    && {!(_patient getVariable ["ACE_isUnconscious", false])}
    && {!(_patient getVariable ["ACME_obtunded", false])}
    && {isNull attachedTo _patient} && {isNull objectParent _patient}) then {
    if (!isNil "ace_medical_engine_fnc_setUnconsciousAnim") then {
        [_patient, false] call ace_medical_engine_fnc_setUnconsciousAnim;
    };
};
_patient setVariable ["ACME_AAJT_collapseOwned", false, false];
