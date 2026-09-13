// B48 chest-seal Flip: the casualty's ACTUAL visual orientation owns the front/back view.
// A Flip does not pre-emptively swap the diagram and then hope the body catches up.  The requested opposite side
// becomes visible as the casualty physically rolls; fn_chestSealTick continuously reclassifies the body.
private _patient = uiNamespace getVariable ["ACME_CS_Patient", objNull];
private _now = diag_tickTime;
private _lockedUntil = uiNamespace getVariable ["ACME_CS_FlipLockedUntil", 0];
if ((_lockedUntil isEqualType 0) && {_lockedUntil > _now}) exitWith {};
if (isNull _patient) exitWith {};

private _uiCurrent = uiNamespace getVariable ["ACME_CS_Side", "front"];
private _actualSide = [_patient, _uiCurrent] call ACME_fnc_chestSealActualSide;
_patient setVariable ["ACME_CS_facing", _actualSide, true];
private _virtualLocked = uiNamespace getVariable ["ACME_CS_VirtualFlip", false];
private _baseSide = if (_virtualLocked) then {_uiCurrent} else {_actualSide};
private _newSide = if (_baseSide == "front") then {"back"} else {"front"};

uiNamespace setVariable ["ACME_CS_Dragging", false];
uiNamespace setVariable ["ACME_CS_DragPt", []];
uiNamespace setVariable ["ACME_CS_DragLast", -1];
uiNamespace setVariable ["ACME_CS_ArchBlend", 0];
uiNamespace setVariable ["ACME_CS_FingerGlow", []];

private _dead = (!alive _patient) || {(lifeState _patient) isEqualTo "DEAD"};
private _self = _patient isEqualTo (uiNamespace getVariable ["ACME_CS_Medic", objNull]);
private _isUncon = (_patient getVariable ["ACE_isUnconscious", false]) || {_patient getVariable ["ace_medical_unconscious", false]};
private _isObtunded = _patient getVariable ["ACME_obtunded", false];
private _isGrounded = _isUncon || _isObtunded || {(stance _patient) == "PRONE"} || {_patient getVariable ["ACM_core_Lying_State", false]};
private _willAnimate = (!_dead) && {!_self} && {_isGrounded} && {isNull objectParent _patient};

// An awake casualty who is standing/crouched under their own control must never be forced to the floor just so
// the medic can inspect the opposite chest surface. Flip the diagnostic canvas only and briefly lock the UI side
// so the live orientation classifier does not immediately snap it back. Dead/vehicle cases retain the actual side.
if (!_willAnimate) exitWith {
    if (!_dead && {!_isUncon} && {!_isObtunded} && {isNull objectParent _patient}) then {
        uiNamespace setVariable ["ACME_CS_Side", _newSide];
        uiNamespace setVariable ["ACME_CS_FlipTarget", ""];
        uiNamespace setVariable ["ACME_CS_FlipLockedUntil", 0];
        uiNamespace setVariable ["ACME_CS_VirtualFlip", true];
    } else {
        uiNamespace setVariable ["ACME_CS_Side", _actualSide];
        uiNamespace setVariable ["ACME_CS_FlipTarget", ""];
    };
    [] call ACME_fnc_chestSealRender;
};

// B57: the diagram follows the requested endpoint once. Do not let intermediate roll geometry flip the UI back
// and forth while the casualty is between supine and prone.
uiNamespace setVariable ["ACME_CS_VirtualFlip", false];
uiNamespace setVariable ["ACME_CS_Side", _newSide];
uiNamespace setVariable ["ACME_CS_FlipTarget", _newSide];

private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
if (!(_rollTime isEqualType 0) || {_rollTime < 0}) then {_rollTime = 1.85;};
private _providerTime = missionNamespace getVariable ["ACME_rollProviderDuration", 2.2];
if (!(_providerTime isEqualType 0) || {_providerTime < 0}) then {_providerTime = 2.2;};

// Provider theatre starts once, locally. B73 routes the exact requested medic4 RTM through an ACME wrapper whose
// move graph explicitly connects to/from empty-handed crouch, so the Flip can enter and exit without a snap.
private _provider = uiNamespace getVariable ["ACME_CS_Medic", objNull];
if (!isNull _provider && {local _provider}) then {[_provider, "chestSealFlip", _patient] call ACME_fnc_rollProviderStart;};

private _until = _now + (_rollTime max _providerTime);
uiNamespace setVariable ["ACME_CS_FlipLockedUntil", _until];
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (!isNull _display) then {
    private _btn = _display displayCtrl 86426;
    if (!isNull _btn) then {
        _btn ctrlEnable false;
        _btn ctrlSetText "Flipping...";
        [{
            disableSerialization;
            private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
            if (!isNull _display) then {
                private _btn = _display displayCtrl 86426;
                if (!isNull _btn) then {
                    _btn ctrlEnable true;
                    _btn ctrlSetText "Flip";
                };
            };
            uiNamespace setVariable ["ACME_CS_FlipLockedUntil", 0];
            uiNamespace setVariable ["ACME_CS_FlipTarget", ""];
        }, [], (_rollTime max _providerTime)] call CBA_fnc_waitAndExecute;
    };
};

[_patient, _newSide] call ACME_fnc_chestSealRoll;
[] call ACME_fnc_chestSealRender;
