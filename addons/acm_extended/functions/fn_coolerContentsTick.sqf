// a local per-player pass, a pfh, over the cooler container store. it runs on each client for its ACE_player.
// a newly-acquired cooler starts its coolant clock and gets pre-filled with its rated units of o-, the fill type.
// while the coolant lasts, the contents are frozen, meaning cold, and nothing ages.
// once the coolant expires, the contents warm and eventually spoil into spoiled blood in the inventory.
// if a cooler is no longer carried, its contents are left in place, preserved in the store and never dumped to
// inventory, so the blood stays inside the cooler and reappears when it is carried again.
// the container contents are virtual rather than real inventory items, so the server cold-chain never
// double-handles them.
if !(missionNamespace getVariable ["ACME_sys_bloodChain", true]) exitWith {};  // the system toggle. fully off means this stops.
if (!hasInterface) exitWith {};
private _p = ACE_player;
if (isNull _p || {!alive _p}) exitWith {};

private _dt      = missionNamespace getVariable ["ACME_coolerContentsDt", 5];
private _spoilT  = missionNamespace getVariable ["ACME_bloodLooseSpoilTime", 1200];
private _thawIn  = missionNamespace getVariable ["ACME_coolerThawRateInside", 0.2];  // the post-coolant thaw rate inside the box, against 1.0 loose.
private _fill    = missionNamespace getVariable ["ACME_coolerFillType", "ON"];
private _store   = _p getVariable ["ACME_coolerStore", createHashMap];
private _coolant = _p getVariable ["ACME_coolerCoolant", createHashMap];
private _changed = false;

private _held = (uniformItems _p) + (vestItems _p) + (backpackItems _p);
private _heldCoolers = _held select { (_x find "ACME_BloodCooler_") == 0 };

// new coolers: start the clock and the initial fill.
{
    private _cc = _x;
    if (isNil { _coolant get _cc }) then {
        _coolant set [_cc, time];
        private _cap = floor ((getNumber (configFile >> "CfgWeapons" >> _cc >> "ACME_coolerCapacityMl")) / 500);
        private _contents = _store getOrDefault [_cc, []];
        if ((count _contents) == 0 && {_cap > 0}) then {
            for "_i" from 1 to _cap do { _contents pushBack [format ["ACM_BloodBag_%1_500", _fill], 0]; };
            _store set [_cc, _contents];
        };
        _changed = true;
    };
} forEach _heldCoolers;

// age and spoil. coolers the medic is not carrying are left completely untouched: their virtual contents stay in
// the store, so the blood stays in the cooler and is never dumped into inventory, and they are preserved until
// the cooler is carried again, when the cold chain resumes. only a carried cooler ages and can spoil.
{
    private _cc = _x;
    if (_cc in _heldCoolers) then {
        private _contents = _store get _cc;
        private _start = _coolant getOrDefault [_cc, time];
        private _chain = getNumber (configFile >> "CfgWeapons" >> _cc >> "ACME_coolerColdChainTime");
        private _cold  = (_chain <= 0) || {(time - _start) < _chain};
        if (!_cold) then {
            private _kept = [];
            private _spoiled = 0;
            {
                _x params ["_bc", "_wt"];
                // the coolant is gone, and the insulated box still slows the thaw. blood kept inside warms a fraction of real
                // time, so it lasts far longer than a loose bag, which warms 1:1 outside and expires in the normal shelf life. it
                // is a slow thaw rather than instant spoilage.
                private _nw = _wt + (_dt * _thawIn);
                if (_nw >= _spoilT && {missionNamespace getVariable ["ACME_bloodSpoilEnabled", true]}) then {
                    if (_p canAdd "ACME_SpoiledBlood") then { _p addItem "ACME_SpoiledBlood"; };
                    _spoiled = _spoiled + 1;
                } else { _kept pushBack [_bc, _nw]; };
            } forEach _contents;
            _store set [_cc, _kept];
            _changed = true;
            if (_spoiled > 0) then { [format ["%1 unit(s) in your %2 spoiled.", _spoiled, getText (configFile >> "CfgWeapons" >> _cc >> "displayName")], 3] call ace_common_fnc_displayTextStructured; };
        };
    };
} forEach (keys _store);

if (_changed) then {
    [_p, "store", _store, false] call ACME_fnc_coolerStateCommit;
    [_p, "coolant", _coolant, false] call ACME_fnc_coolerStateCommit;
    if (!isNull (uiNamespace getVariable ["ACME_CLR_DLG", displayNull])) then { call ACME_fnc_coolerRefresh; };
};
