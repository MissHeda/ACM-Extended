// the HPMK unwrapped-blanket cutout overlay, shown in the prepped state.
// it is created as the first runtime overlay, because its handler is registered before the others, so it sits at the
// bottom of the runtime stack. combined with the transparent body-shaped cut-out in HPMK_unwrapped_ca.paa, the
// silhouette and all the icons show through the hole and the blanket reads as being behind the body.
params ["_ctrlGroup", "_target"];
if (isNull _ctrlGroup) exitWith {};
private _ref = _ctrlGroup controlsGroupCtrl 70113;  // idc_body_torso_io full-image rect
private _c = _ctrlGroup controlsGroupCtrl 7291000;
if (isNull _c) then {
    _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", 7291000, _ctrlGroup];
    if (!isNull _ref) then { _c ctrlSetPosition (ctrlPosition _ref); };
    _c ctrlSetText "\acm_extended\ui\items\HPMK_unwrapped_ca.paa";
    _c ctrlCommit 0;
};
_c ctrlShow (!isNull _target && {(_target getVariable ["ACME_hpmk_state", ""]) == "prepped"});
