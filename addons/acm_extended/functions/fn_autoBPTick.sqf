// the per-patient auto-bp driver. when active, it silently presses the real AED NIBP cuff of ACM every interval.
// ACM owns the cuff sound, the busy flag, the delay and the aed_nibp_display update.
ACME_autoBP_patients = ACME_autoBP_patients select {
    !isNull _x && {local _x} && {_x getVariable ["ACME_autoBP_Active", false]}
};

if !(missionNamespace getVariable ["ACME_sys_autoBP", true]) exitWith {};
private _interval = missionNamespace getVariable ["ACME_autoBP_interval", 120];
private _now = CBA_missionTime;

{
    private _patient = _x;
    if !(local _patient) then {continue};

    private _hasAED = if (!isNil "ACM_circulation_fnc_hasAED") then {[_patient, "", 3] call ACM_circulation_fnc_hasAED} else {false};
    if (!_hasAED) then {
        [_patient, "ACME_autoBP_Active", false] call ACME_fnc_setVarNet;
        continue;
    };

    if (_now >= (_patient getVariable ["ACME_autoBP_NextTime", _now])) then {
        private _busy = _patient getVariable ["ACM_circulation_AED_PressureCuffBusy", false];
        if (_busy) then {
            [_patient, "ACME_autoBP_NextTime", _now + 5] call ACME_fnc_setVarNet;
            continue;
        };

        private _medic = _patient getVariable ["ACME_autoBP_Medic", objNull];
        if (isNull _medic) then {_medic = _patient getVariable ["ACM_circulation_AED_Provider", objNull];};
        if (isNull _medic && {!isNil "ACE_player"}) then {_medic = ACE_player;};
        if (isNull _medic) then {_medic = player;};

        private _canMeasure = false;
        if (!isNil "ACM_circulation_fnc_AED_CanMeasureBP") then {
            _canMeasure = [_medic, _patient, ""] call ACM_circulation_fnc_AED_CanMeasureBP;
        } else {
            _canMeasure = _hasAED;
        };

        if (_canMeasure && {!isNil "ACM_circulation_fnc_AED_MeasureBP"}) then {
            [_patient, "ACME_autoBP_NextTime", _now + _interval] call ACME_fnc_setVarNet;
            [_medic, _patient] call ACM_circulation_fnc_AED_MeasureBP;
        } else {
            [_patient, "ACME_autoBP_NextTime", _now + 5] call ACME_fnc_setVarNet;
        };
    };
} forEach ACME_autoBP_patients;
