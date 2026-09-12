/* B17: shared dose-driven induction/maintenance for AI and players. ETT presence is never a sedative.
   The same medication state now drives patient physiology regardless of player ownership.
   Release only a state this worker induced. Explicit native stability/forced-state gates protect other clinical causes before WakeUp. */
params ["_patient"];
if (isNull _patient || {!local _patient} || {!alive _patient} || {!(_patient isKindOf "CAManBase")}) exitWith {};
private _load = [_patient] call ACME_fnc_sedationOnBoard;
private _maint = call ACME_fnc_sedationThreshold;
private _owned = _patient getVariable ["ACME_ket_sedated", false];
private _uncon = _patient getVariable ["ACE_isUnconscious", false];
if (_load >= (if (_owned) then {_maint} else {1})) then {
    if (_owned && {_uncon}) then {
        [_patient, [["lastWakeUpCheck", CBA_missionTime, false]]] call ACM_core_fnc_setAceMedicalState;
    };
    // Do not claim unconsciousness caused by shock, arrest, pain, or a paralytic.
    if (!_uncon && {!(_patient getVariable ["ACME_roc_paralyzed", false])}) then {
        [_patient, "ACME_ket_sedated", true] call ACME_fnc_setVarNet;
        [_patient, true, 0, false] call ace_medical_fnc_setUnconscious;
    };
} else {
    if (_owned) then {
        [_patient, "ACME_ket_sedated", false] call ACME_fnc_setVarNet;
        if (_uncon && {!(_patient getVariable ["ace_medical_inCardiacArrest", false])}
            && {!(_patient getVariable ["ACME_roc_paralyzed", false])}
            && {!(_patient getVariable ["ACM_core_KnockOut_State", false])}
            && {!([_patient] call ACM_core_fnc_isForcedUnconscious)}
            && {[_patient] call ace_medical_status_fnc_hasStableVitals}) then {
            ["ace_medical_WakeUp", _patient] call CBA_fnc_localEvent;
        };
    };
};
