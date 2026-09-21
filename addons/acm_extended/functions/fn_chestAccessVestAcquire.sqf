// Temporarily remove a worn plate carrier for a true chest-access action. If Semi-Fowler has no backpack the
// support carrier is already owned by the head-elevation system, so there is nothing additional to remove. If a
// backpack supports Semi-Fowler (or the casualty is simply flat), take exact custody of the worn carrier and park
// its visual beyond the head until the final chest-access lease ends.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {false};

private _saved = +(_patient getVariable ["ACME_chestAccess_vestLoadout", []]);
if ((count _saved) == 2) exitWith {
    [_patient] call ACME_fnc_chestAccessVestPark;
    true
};

private _vestClass = vest _patient;
if (_vestClass == "") exitWith {false};
private _vestEntry = (getUnitLoadout _patient) param [4, [], [[]]];
if ((count _vestEntry) != 2) exitWith {false};

removeVest _patient;
if ((vest _patient) != "") exitWith {false};

private _model = getText (configFile >> "CfgWeapons" >> _vestClass >> "model");
private _prop = objNull;
if (_model != "") then {_prop = createSimpleObject [_model, [0,0,0], false];};
if (isNull _prop) then {
    // Visual fallback only. The saved loadout remains authoritative and the holder is deleted on restore.
    _prop = createVehicle ["GroundWeaponHolder", getPosATL _patient, [], 0, "CAN_COLLIDE"];
    _prop addItemCargoGlobal [_vestClass, 1];
};
_patient setVariable ["ACME_chestAccess_vestLoadout", +_vestEntry, true];
_patient setVariable ["ACME_chestAccess_vestProp", _prop, true];
[_patient] call ACME_fnc_chestAccessVestPark;

// Keep the prop physically above the head throughout long actions such as CPR and thoracostomy. This is a visual
// watchdog only; it never changes the clinical state or the treatment lease.
private _old = _patient getVariable ["ACME_chestAccess_vestPFH", -1];
if (_old isEqualType 0 && {_old >= 0}) then {[_old] call CBA_fnc_removePerFrameHandler;};
private _pfh = [{
    params ["_args", "_handle"];
    _args params ["_p"];
    if (isNull _p || {!local _p} || {(count (_p getVariable ["ACME_chestAccess_vestLoadout", []])) != 2}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (!isNull _p) then {_p setVariable ["ACME_chestAccess_vestPFH", -1, false];};
    };

    // Dead/disconnected providers and impossible long-lived leases must not strand the carrier forever. Real CPR
    // and thoracostomy scopes normally release explicitly; this only cleans abandoned ownership.
    private _leases = _p getVariable ["ACME_chestAccess_leases", createHashMap];
    private _dirty = false;
    {
        private _entry = _leases get _x;
        private _m = _entry param [0,objNull,[objNull]];
        private _at = _entry param [1,CBA_missionTime,[0]];
        if (isNull _m || {!alive _m} || {CBA_missionTime - _at > 900}) then {
            _leases deleteAt _x;
            _dirty = true;
        };
    } forEach keys _leases;
    if (_dirty) then {
        _p setVariable ["ACME_chestAccess_leases",_leases,true];
        private _thora = false;
        {if (((_leases get _x) param [2,"",[""]]) == "thoracostomy") exitWith {_thora = true;};} forEach keys _leases;
        _p setVariable ["ACME_Thora_ChestAccessActive",_thora,true];
    };
    if ((count _leases) == 0) exitWith {[_p] call ACME_fnc_chestAccessVestRestore;};
    [_p] call ACME_fnc_chestAccessVestPark;
}, 0.20, [_patient]] call CBA_fnc_addPerFrameHandler;
_patient setVariable ["ACME_chestAccess_vestPFH", _pfh, false];
true
