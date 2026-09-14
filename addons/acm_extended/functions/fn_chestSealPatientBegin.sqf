// Begin the temporary casualty state used by the chest-seal minigame.
// The first viewer owns preparation. Additional viewers share the same state and do not strip gear twice.
params [
    ["_patient", objNull, [objNull]],
    ["_token", "", [""]]
];
if (isNull _patient || {_token == ""}) exitWith {};
if (!local _patient) exitWith {
    [_patient, "chestSealPatientBegin", [_patient, _token]] call ACME_fnc_ownerDispatch;
};

private _tokens = +(_patient getVariable ["ACME_CS_ProcedureTokens", []]);
if (_token in _tokens) exitWith {};
private _first = _tokens isEqualTo [];
_tokens pushBack _token;
_patient setVariable ["ACME_CS_ProcedureTokens", _tokens, true];
_patient setVariable ["ACME_CS_ProcedureActive", true, true];

// A second medic joins the already prepared workspace. The existing ready time is authoritative.
if (!_first) exitWith {};

private _preSide = [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide;
private _preHeadElev = _patient getVariable ["ACME_headElevated", false];
private _preRecovery = _patient getVariable ["ACM_airway_RecoveryPosition_State", false];
private _preLying = _patient getVariable ["ACM_core_Lying_State", false];
private _preAnim = animationState _patient;
private _preGrounded = _preHeadElev || _preLying
    || {_patient getVariable ["ACE_isUnconscious", false]}
    || {_patient getVariable ["ace_medical_unconscious", false]}
    || {_patient getVariable ["ACME_obtunded", false]}
    || {(stance _patient) == "PRONE"};
_patient setVariable ["ACME_CS_PreProcedureState", [_preSide, _preHeadElev, _preRecovery, _preLying, _preAnim], true];
_patient setVariable ["ACME_CS_ProcedureGrounded", _preGrounded, true];
_patient setVariable ["ACME_CS_facing", _preSide, true];
_patient setVariable ["ACME_CS_rollUntil", -1, false];

private _readyAt = CBA_missionTime + 0.12;

// A Semi-Fowler casualty is laid flat once, before the minigame. Keep the support carrier out of the chest
// workspace instead of putting it back on the patient while flat.
if (_preHeadElev) then {
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
    [_patient, true] call ACME_fnc_headElevSuspend;
    private _headReady = _patient getVariable ["ACME_headElev_suspendReadyAt", -1];
    if (_headReady > _readyAt) then {_readyAt = _headReady + 0.08;};
};

// If the carrier is still worn, take exact custody of its loadout for the duration of the procedure. This also
// covers Semi-Fowler patients supported by a backpack, where head elevation itself never removed the carrier.
private _vestClass = vest _patient;
private _vestEntry = (getUnitLoadout _patient) param [4, [], [[]]];
_patient setVariable ["ACME_CS_vestLoadout", [], true];
_patient setVariable ["ACME_CS_vestProp", objNull, true];
if (_vestClass != "" && {(count _vestEntry) == 2} && {isNull objectParent _patient}) then {
    removeVest _patient;
    if ((vest _patient) == "") then {
        _patient setVariable ["ACME_CS_vestLoadout", +_vestEntry, true];
        private _model = getText (configFile >> "CfgWeapons" >> _vestClass >> "model");
        if (_model != "") then {
            // Use the carrier model as a static prop. fn_chestSealParkCarrier disables patient collision explicitly.
            private _prop = createSimpleObject [_model, [0,0,0], false];
            if (!isNull _prop) then {
                _patient setVariable ["ACME_CS_vestProp", _prop, true];
            };
        };
    };
};

[_patient] call ACME_fnc_chestSealParkCarrier;
_patient setVariable ["ACME_CS_ProcedureReadyAt", _readyAt, true];
