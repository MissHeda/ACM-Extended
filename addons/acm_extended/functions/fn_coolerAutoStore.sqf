// auto-store received blood into a carried blood cooler that has room.
// it fires on a loadout change of the player, from a pickup, a hand-off or an arsenal close. for each cooler the
// player carries, if it has free capacity, pull loose blood bags from the inventory of the player into it,
// resetting the warm clock of each bag as it goes cold, until the cooler is full or no loose blood remains.
// it prioritizes empty coolers first, so a freshly received unit lands in the empty carrier as the user asked, and
// then tops up partially filled ones.
// it is gated by ACME_coolerAutoStore, which defaults to true. it is local to the player, and the cooler store
// lives on ACE_player.
if (!hasInterface) exitWith {};
if (!(missionNamespace getVariable ["ACME_coolerAutoStore", true])) exitWith {};
// a reentry guard: the removeitem below fires another loadout event, which would recurse. skip if we are already
// inside.
if (missionNamespace getVariable ["ACME_coolerAutoStoreBusy", false]) exitWith {};
// a suppression window: after a manual unload, where the medic pulled a unit out to use it, do not immediately
// re-store it.
if (diag_tickTime < (missionNamespace getVariable ["ACME_coolerAutoStoreSuppressUntil", 0])) exitWith {};

private _p = ACE_player;
if (isNull _p || {!alive _p}) exitWith {};

private _coolerClasses = ["ACME_BloodCooler_CSWB1U", "ACME_BloodCooler_CSWB2U", "ACME_BloodCooler_CSWB4U"];
private _carried = items _p;
// which cooler classes are actually in the kit?
private _haveCoolers = _coolerClasses select { _x in _carried };
if (_haveCoolers isEqualTo []) exitWith {};

// is there any loose blood to store? the ACM blood bag classes are ACM_BloodBag_* and ACM_FreshBloodBag_*.
private _looseBlood = (uniformItems _p) + (vestItems _p) + (backpackItems _p);
_looseBlood = _looseBlood select { (_x find "ACM_BloodBag_" == 0) || {_x find "ACM_FreshBloodBag_" == 0} };
// reconcile the manually-out reservation to the actual loose count now, before the no-loose-blood early-out below.
// the reservation is banked by manual unloads and is only meant to keep that many pulled units loose. it was only
// clamped later in the storable math, which is skipped whenever nothing is loose. so a reservation from earlier
// unloads, such as 3 pulled and then all hung, never released while the loose blood sat at 0, and every
// later-received unit was then wrongly reserved and never auto-stored, so the cooler stayed permanently empty.
// clamping here releases it.
missionNamespace setVariable ["ACME_coolerManualOut", ((missionNamespace getVariable ["ACME_coolerManualOut", 0]) min (count _looseBlood))];
if (_looseBlood isEqualTo []) exitWith {};

// honor deliberately unloaded units: leave ACME_coolerManualOut loose bags alone, so blood the medic pulled out
// stays out. clamp the keep-out count to what is actually loose right now, so once those bags are spiked or used,
// or manually re-loaded, the loose count drops, the reservation shrinks, and freshly picked-up blood auto-stores
// again as normal.
private _looseCount = count _looseBlood;
private _manualOut = (missionNamespace getVariable ["ACME_coolerManualOut", 0]) min _looseCount;
missionNamespace setVariable ["ACME_coolerManualOut", _manualOut];
private _storable = (_looseCount - _manualOut) max 0;
if (_storable <= 0) exitWith {};

private _store = _p getVariable ["ACME_coolerStore", createHashMap];

// order the coolers: empty ones first, per the rule that if our cooler is empty we store it, then any with free
// space.
private _empties = [];
private _partials = [];
{
    private _cap = floor ((getNumber (configFile >> "CfgWeapons" >> _x >> "ACME_coolerCapacityMl")) / 500);
    private _used = count (_store getOrDefault [_x, []]);
    if (_used < _cap) then {
        if (_used == 0) then { _empties pushBack [_x, _cap] } else { _partials pushBack [_x, _cap] };
    };
} forEach _haveCoolers;
private _ordered = _empties + _partials;
if (_ordered isEqualTo []) exitWith {};

missionNamespace setVariable ["ACME_coolerAutoStoreBusy", true];
private _stored = 0;
{
    _x params ["_coolerClass", "_cap"];
    private _contents = _store getOrDefault [_coolerClass, []];
    // re-read the loose blood for each cooler, because we remove as we go.
    private _loose = (uniformItems _p) + (vestItems _p) + (backpackItems _p);
    _loose = _loose select { (_x find "ACM_BloodBag_" == 0) || {_x find "ACM_FreshBloodBag_" == 0} };
    {
        if (count _contents >= _cap) exitWith {};  // this cooler is full.
        if (_stored >= _storable) exitWith {};  // the manually-out units are reserved, so stop.
        private _bag = _x;
        if (_bag in ((uniformItems _p) + (vestItems _p) + (backpackItems _p))) then {
            _p removeItem _bag;
            _contents pushBack [_bag, 0];  // cold now.
            _stored = _stored + 1;
        };
    } forEach _loose;
    _store set [_coolerClass, _contents];
} forEach _ordered;

missionNamespace setVariable ["ACME_coolerAutoStoreBusy", false];

if (_stored > 0) then {
    [_p, "store", _store, false] call ACME_fnc_coolerStateCommit;
    [format ["%1 blood unit%2 stored cold in your cooler.", _stored, if (_stored == 1) then {""} else {"s"}], 2.5, _p] call ace_common_fnc_displayTextStructured;
    // refresh the manager if it happens to be open.
    if (!isNull (uiNamespace getVariable ["ACME_CLR_DLG", displayNull])) then { call ACME_fnc_coolerRefresh; };
};
