// cancel the pre-raise animation if the treatment or progress bar is interrupted before the bag is up.
params ["_medic"];
if (isNull _medic || {!local _medic}) exitWith {};
_medic setVariable ["ACME_hang_Raising", false];
if !(_medic getVariable ["ACME_hang_Active", false]) then {
    [_medic, ""] call ACME_fnc_doAnimHeld;
    _medic enableAI "ANIM";
    private _savedSlots = _medic getVariable ["ACME_hang_savedWeaponSlots", []];
    if !(_savedSlots isEqualTo []) then {
        private _ld = getUnitLoadout _medic;
        _ld set [0, _savedSlots select 0];
        _ld set [1, _savedSlots select 1];
        _medic setUnitLoadout _ld;
        _medic setVariable ["ACME_hang_savedWeaponSlots", nil];
    };
    _medic selectWeapon "";
    _medic setUnitPos "MIDDLE";
    [_medic, "AmovPknlMstpSnonWnonDnon", 1] call ACME_fnc_doAnim;

    if ((_medic getVariable ["ACME_DP_PauseTreatmentClass", ""]) == "hangbag") then {
        _medic setVariable ["ACME_DP_Paused", false, false];
        _medic setVariable ["ACME_DP_PauseTreatmentClass", "", false];
        _medic setVariable ["ACME_DP_IdleStart", CBA_missionTime, false];
    };
};
