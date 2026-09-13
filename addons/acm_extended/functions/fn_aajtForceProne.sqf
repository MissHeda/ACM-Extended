/* Owner-local Zone 3 mechanical collapse. It uses the engine unconscious animation as a short ragdoll only;
   ACE medical consciousness is never changed. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {[_patient, "register", []] call ACME_fnc_ownerDispatch;};
if (!(_patient getVariable ["ACME_AAJT_zone3", false]) || {_patient getVariable ["ACE_isUnconscious", false]}
    || {!isNull objectParent _patient} || {!isNull attachedTo _patient}) exitWith {};
private _last = _patient getVariable ["ACME_AAJT_downedAt", -10];
if ((time - _last) < 0.8 || {_patient getVariable ["ACME_AAJT_collapseOwned", false]}) exitWith {};
_patient setVariable ["ACME_AAJT_downedAt", time, false];
_patient setVariable ["ACME_AAJT_collapseOwned", true, false];
_patient setUnitPos "AUTO";
if (!isNil "ace_medical_engine_fnc_setUnconsciousAnim") then {
    [_patient, true] call ace_medical_engine_fnc_setUnconsciousAnim;
};
[{
    params ["_patient", "_epoch"];
    if (isNull _patient || {!local _patient} || {!alive _patient}
        || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}
        || {!(_patient getVariable ["ACME_AAJT_zone3", false])}) exitWith {};
    if (_patient getVariable ["ACE_isUnconscious", false] || {!isNull objectParent _patient} || {!isNull attachedTo _patient}) exitWith {
        _patient setVariable ["ACME_AAJT_collapseOwned", false, false];
    };
    if (!isNil "ace_medical_engine_fnc_setUnconsciousAnim") then {[_patient, false] call ace_medical_engine_fnc_setUnconsciousAnim;};
    _patient setVariable ["ACME_AAJT_collapseOwned", false, false];
    _patient setUnitPos "DOWN";
    [_patient, "AmovPpneMstpSnonWnonDnon", 2] call ACME_fnc_doAnim;
}, [_patient, [_patient] call ACME_fnc_clinicalEpoch], missionNamespace getVariable ["ACME_aajt_collapseTime", 0.45]] call CBA_fnc_waitAndExecute;
