// NA2 owner lifecycle. One shared recovery scan supplements event-driven registration.
if (missionNamespace getVariable ["ACME_NA2_ownerInstalled", false]) exitWith {};
ACME_NA2_ownerInstalled = true;
["ACME_ownerCommand", { isNil { _this call ACME_fnc_ownerDispatch; }; }] call CBA_fnc_addEventHandler;
["ACME_netNotice", { _this call ACME_fnc_netNotice; }] call CBA_fnc_addEventHandler;
["ACME_hpmkReturnItem", {
    params [["_receiver", objNull, [objNull]]];
    if (!isNull _receiver && {local _receiver}) then {
        [_receiver, "ACM_HPMK"] call ace_common_fnc_addToInventory;
    };
}] call CBA_fnc_addEventHandler;
["ACME_nrbDraw", { isNil { _this call ACME_fnc_nrbOxygenDraw; }; }] call CBA_fnc_addEventHandler;
["ACME_nrbSound", { _this call ACME_fnc_nrbSoundServer; }] call CBA_fnc_addEventHandler;
["ACME_thoraOutput", { if (isServer) then { isNil { _this call ACME_fnc_thoraOutput; }; }; }] call CBA_fnc_addEventHandler;
["CAManBase", "Local", {
    params ["_unit", "_isLocal"];
    [_unit] call ACME_fnc_aajtDownedStop;
    private _headPFH = _unit getVariable ["ACME_headElev_pfh", -1];
    if (_headPFH >= 0) then {[_headPFH] call CBA_fnc_removePerFrameHandler;};
    _unit setVariable ["ACME_headElev_pfh", -1];
    private _headEH = _unit getVariable ["ACME_headElev_killEH", -1];
    if (_headEH >= 0) then {_unit removeEventHandler ["Killed", _headEH];};
    _unit setVariable ["ACME_headElev_killEH", -1];
    _unit setVariable ["ACME_net_scalarCache", createHashMap, false];
    _unit setVariable ["ACME_net_cacheOwner", [], false];
    _unit setVariable ["ACME_clinicalLastOwner", -1];
    _unit setVariable ["ACME_nativeWorkerOwner", nil, false];
    _unit setVariable ["ACME_alt_ptxSample", nil, false];
    _unit setVariable ["ACME_nativeVomitWorker", [], false];
    {
        private _h = _unit getVariable [_x, -1];
        if (_h >= 0) then {[_h] call CBA_fnc_removePerFrameHandler;};
        _unit setVariable [_x, -1, false];
    } forEach ["ACM_circulation_CardiacArrest_PFH", "ACM_circulation_ReversibleCardiacArrest_PFH", "ACM_airway_AirwayObstructionVomit_PFH", "ACM_breathing_Pneumothorax_PFH"];
    {if ((_x find "acme_clock_") == 0) then {_unit setVariable [_x, nil, false];};} forEach allVariables _unit;
    private _juncHandle = _unit getVariable ["ACME_juncPFH", -1];
    if (_juncHandle >= 0) then {[_juncHandle] call CBA_fnc_removePerFrameHandler;};
    _unit setVariable ["ACME_juncPFH", -1]; _unit setVariable ["ACME_juncWorker", []];
    // Remove stale machine-local work immediately, including a quick away/back transfer.
    {
        private _list = missionNamespace getVariable [_x, []];
        missionNamespace setVariable [_x, _list - [_unit]];
    } forEach ["ACME_nrb_activePatients", "ACME_hpmk_activePatients", "ACME_tbi_activePatients", "ACME_cs_activePatients", "ACME_autoBP_patients", "ACME_clinical_activePatients", "ACME_infusion_activePatients", "ACME_circ_activePatients"];
    private _drain = _unit getVariable ["ACME_thora_drainPFH", -1];
    if (_drain >= 0) then { [_drain] call CBA_fnc_removePerFrameHandler; };
    _unit setVariable ["ACME_thora_drainPFH", -1, false];
    _unit setVariable ["ACME_nrb_lastTickLocal", nil, false];
    _unit setVariable ["ACME_hpmk_lastTickLocal", nil, false];
    _unit setVariable ["ACME_nrb_lastDrawSend", -1, false];
    _unit setVariable ["ACME_nrb_sfxWanted", nil, false];
    if (_isLocal) then {
        [_unit] call ACME_fnc_ownerRegister;
        [{ _this call ACME_fnc_ownerRegister; }, [_unit]] call CBA_fnc_execNextFrame;
        [{ _this call ACME_fnc_ownerRegister; }, [_unit], 0.5] call CBA_fnc_waitAndExecute;
    };
}] call CBA_fnc_addClassEventHandler;
["CAManBase", "init", {
    [{ _this call ACME_fnc_ownerRegister; }, [_this select 0]] call CBA_fnc_execNextFrame;
}, true, [], true] call CBA_fnc_addClassEventHandler;
[{
    ACME_clinical_ownedUnits = allUnits select {local _x && {alive _x}};
    {[_x] call ACME_fnc_ownerRegister;} forEach ACME_clinical_ownedUnits;
    {
        missionNamespace setVariable [_x, (missionNamespace getVariable [_x, []]) select {!isNull _x && {local _x} && {alive _x}}];
    } forEach ["ACME_nrb_activePatients", "ACME_hpmk_activePatients", "ACME_tbi_activePatients", "ACME_cs_activePatients", "ACME_autoBP_patients", "ACME_clinical_activePatients", "ACME_infusion_activePatients", "ACME_circ_activePatients"];
}, 1, []] call CBA_fnc_addPerFrameHandler;
if (isServer) then {
    ACME_nrb_soundRegistry = createHashMap;
    [{
        {
            private _entry = ACME_nrb_soundRegistry get _x;
            _entry params ["_patient", "_source", "_at"];
            if (isNull _patient || {!alive _patient} || {
                CBA_missionTime > _at + 2 && {
                    !(_patient getVariable ["ACME_nrb_on", false]) || {!(_patient getVariable ["ACME_nrb_hasO2", false])}
                }
            }) then {
                if (!isNull _source) then { deleteVehicle _source; };
                ACME_nrb_soundRegistry deleteAt _x;
            };
        } forEach (keys ACME_nrb_soundRegistry);
    }, 0.5, []] call CBA_fnc_addPerFrameHandler;
};
