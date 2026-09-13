// stage 1 of the HPMK: prep the kit. this was the old single-step wrap.
// it takes the reusable kit out of the hands of the provider, recovered on removal, and sets the state to prepped,
// which reveals the wrap and remove buttons and shows the unwrapped-blanket body overlay. rewarming does not start
// yet, because that is the wrap.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (isNull _medic || {isNull _patient}) exitWith {};

private _lyingState = _patient getVariable ["ACM_core_Lying_State", false];
private _isLying = if (_lyingState isEqualType true) then {_lyingState} else {_lyingState > 0};
private _eligible = (_patient getVariable ["ACE_isUnconscious", false]) || {_isLying};
// Manual prone is still a mobile state. HPMK requires medical unconsciousness or ACM's explicit lying state.
if (!_eligible) exitWith {};
if (([_medic, "ACM_HPMK"] call ace_common_fnc_getCountOfItem) <= 0) exitWith {};
if ((_patient getVariable ["ACME_hpmk_state", ""]) != "") exitWith {
    ["This patient already has an HPMK prepped or applied.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
_medic removeItem "ACM_HPMK";  // out of the kit / laid on the patient. recovered on removal
// Remember whose reusable kit this is for mobility transitions that have no explicit Get Up initiator. Explicit
// Get Up passes its own receiver and therefore returns the kit to the patient/provider who pressed that action.
_patient setVariable ["ACME_hpmk_provider", _medic, true];
_patient setVariable ["ACME_hpmk_returnPending", false, true];
[_patient, "prepped", true, false] call ACME_fnc_hpmkStateCommit;
["HPMK prepped. Wrap to begin rewarming, or remove to stow it.", 3, _medic] call ace_common_fnc_displayTextStructured;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "NAR HPMK prepped", []] call ace_medical_treatment_fnc_addToLog;
};
