// the HPMK body overlays, on top of the stack: the fully-wrapped image, shown in the wrapped state, and the
// partially-exposed-chest image, shown in the exposed state, where the chest and left arm are open and the right
// arm and legs are wrapped.
// both clone the rect of torso_io, and the per-limb icons sit under them. the prepped cutout is handled
// separately.
params ["_ctrlGroup", "_target"];
if (isNull _ctrlGroup) exitWith {};
private _ref = _ctrlGroup controlsGroupCtrl 70113;
private _state = if (isNull _target) then {""} else {_target getVariable ["ACME_hpmk_state", ""]};

// the fully-wrapped overlay.
private _c = _ctrlGroup controlsGroupCtrl 7291001;
if (isNull _c) then {
    _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", 7291001, _ctrlGroup];
    if (!isNull _ref) then { _c ctrlSetPosition (ctrlPosition _ref); };
    _c ctrlSetText "\acm_extended\ui\items\body_background_wrapped.paa";
    _c ctrlCommit 0;
};
_c ctrlShow (_state == "wrapped");

// the partially-exposed-chest overlay.
private _ce = _ctrlGroup controlsGroupCtrl 7291002;
if (isNull _ce) then {
    _ce = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", 7291002, _ctrlGroup];
    if (!isNull _ref) then { _ce ctrlSetPosition (ctrlPosition _ref); };
    _ce ctrlSetText "\acm_extended\ui\items\body_background_exposed.paa";
    _ce ctrlCommit 0;
};
_ce ctrlShow (_state == "exposed");
