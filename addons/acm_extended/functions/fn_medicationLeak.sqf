/* Tissue injury receives leaked mass ONLY, at the selected access.
   Native/systemic observers cannot assign an unrelated IV's injury to a sound IV or IO. */
params ["_patient", "_part", "_site", "_class", "_leaked", ["_infusion", false]];
if (isNull _patient || {!local _patient} || {_leaked <= 0} || {_site < 0}) exitWith {};
private _ledger = _patient getVariable ["ACME_medicationLeaked", createHashMap];
private _key = format ["%1:%2:%3",toLowerANSI _part,_site,_class];
_ledger set [_key, (_ledger getOrDefault [_key,0]) + _leaked];
[_patient,"ACME_medicationLeaked",_ledger] call ACME_fnc_setVarNet;
if !(missionNamespace getVariable ["ACME_vesicant_enabled",true]) exitWith {};
private _rows = (missionNamespace getVariable ["ACME_vesicant_table",[]]) select {(_x select 0) == _class};
if (_rows isEqualTo []) then {
    // Non-vesicants cause infiltration, not the listed vesicant's necrosis/pain tier.
    private _base = (_class splitString "_") select 0;
    private _stock = getNumber (configFile >> "ACM_Medication" >> "Concentration" >> _base >> "concentration");
    // Default infiltration threshold is ten mL of stock-equivalent, not ten mg of every unlike drug.
    if (_stock > 0) then {
        [_patient,_part,_class,_leaked,_stock * 10,0.25,"irritant","hyaluronidase",1,_site] call ACME_fnc_vesicantInjure;
    };
} else {
    (_rows select 0) params ["_cn","_threshold",["_pain",1],["_tier","vesicant"],["_antidote","hyaluronidase"],["_bruise",0],["_infMult",1]];
    [_patient,_part,_class,_leaked,(_threshold max 0.01),_pain,_tier,_antidote,_bruise,_site] call ACME_fnc_vesicantInjure;
};
