// inflict a junctional wound on a part, meaning the chest, arms or legs. it is script-callable for scenarios and
// zeus, as [_unit, "leftarm"] call ACME_fnc_junctionalInflict.
// it is also called by fn_junctionalrollspawn, the auto-spawn off velocity and avulsion wounds, and by the [TEST]
// action.
// it sets the state to open and starts the high arterial-bleed drain, which is a life threat controlled only by the
// gauze into pressure flow.
// junctional wounds are limbs only, meaning the arms and legs. the chest, body, was removed, because penetrating
// chest trauma is handled by the chest-seal path instead.
params ["_unit", "_part", ["_silent", false], ["_epoch", -1]];
if (_epoch < 0) then {_epoch = [_unit] call ACME_fnc_clinicalEpoch;};
if (!local _unit) exitWith {[_unit, "junctionalInflict", [_unit, _part, _silent, _epoch]] call ACME_fnc_ownerDispatch;};
if (_epoch != ([_unit] call ACME_fnc_clinicalEpoch)) exitWith {};
private _p = toLower _part;
if !(_p in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {
    ["Junctional wounds only apply to the arms or legs.", 2.5] call ace_common_fnc_displayTextStructured;
};
_unit setVariable [format ["ACME_Junc_%1", _p], "open", true];
[_unit] call ACME_fnc_junctionalStartBleed;
// If the new junction is already beneath an AAJT-S placement, immediately recompute native wound loss for that
// limb. Zone 3, unilateral inguinal and axillary placements all use the same central occlusion predicate.
private _partIndex = ["head","body","leftarm","rightarm","leftleg","rightleg"] find _p;
if ([_unit, _partIndex] call ACME_fnc_aajtOccludes) then {[_unit, _p, true] call ACME_fnc_aajtSetLegTQ;};
// this used to be ["leftarm",...] select (["leftarm",...] find _p), which is an elaborate way of returning
// _p unchanged, so the hint read "Axillary hemorrhage: leftarm."
private _label = [_p, "short"] call ACME_fnc_bodyPartName;
if (!_silent) then {
    private _hcDesc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
    private _term = if (_hcDesc) then { if (_p in ["leftarm","rightarm"]) then {"Axillary"} else {"Inguinal"} } else {"Junctional"};
    [format ["%1 hemorrhage: %2.", _term, _label], 2.5] call ace_common_fnc_displayTextStructured;
};
