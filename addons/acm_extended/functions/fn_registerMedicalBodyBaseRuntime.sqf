/*
 * Phase 25 subsystem ownership: Base medical-body overlays for HPMK, NRB and junctional wounds plus junctional GUI reconciliation.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

// HPMK unwrapped cutout overlay. it registers first so it is the lowest runtime control, and with the
// transparent body cut-out it reads as sitting behind the body. it must come before the NRB, junctional and
// wrapped handlers below.
["ace_medical_gui_updateBodyImage", {_this call ACME_fnc_updateHpmkUnwrapped}] call CBA_fnc_addEventHandler;

// body-image overlay. this shows the blue NRB mask icon on the medical body while the mask is on.
// do not add a control to ACM's body-image group through config. re-opening ace_medical_gui_BodyImage or its
// controls drops the inherited background-derived silhouette and blanks the whole body image. instead this
// registers a handler on ACM's own draw event, "ace_medical_gui_updateBodyImage" with [_ctrlGroup, _target,
// _selectionN], and creates the overlay control at runtime, parented to the live control group. it clones the
// position of the igel head overlay so it lands on the head. a runtime control renders on top, so it sits over
// the igel. the control is destroyed with the display, so a fresh menu re-creates it. there is no leak and no
// config risk.
["ace_medical_gui_updateBodyImage", {
    params ["_ctrlGroup", "_target"];
    if (isNull _ctrlGroup) exitWith {};
    private _c = _ctrlGroup controlsGroupCtrl 7283100;  // our NRB overlay
    if (isNull _c) then {
        // clone the position of the head airway overlay so the mask lands on the head.
        private _ref = _ctrlGroup controlsGroupCtrl 70102;  // idc_body_head_igel
        if (isNull _ref) then { _ref = _ctrlGroup controlsGroupCtrl 70100; };  // fallback: head_opa
        _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", 7283100, _ctrlGroup];
        if (!isNull _ref) then { _c ctrlSetPosition (ctrlPosition _ref); };
        _c ctrlSetText "\acm_extended\ui\items\nrbmask_oxygen_ca.paa";
        _c ctrlSetTextColor (["oxygen", 1] call ACME_fnc_a11yColor);  // oxygen cue
        _c ctrlCommit 0;
    };
    _c ctrlShow (!isNull _target && {_target getVariable ["ACME_nrb_on", false]});
}] call CBA_fnc_addEventHandler;

// junctional wound and wrap overlays. this uses the same runtime-create pattern, with one handler for all four
// limbs.
["ace_medical_gui_updateBodyImage", {_this call ACME_fnc_updateJunctionalImage}] call CBA_fnc_addEventHandler;
// Keep already-open medical menus coherent when another provider changes a networked junctional state.
// The poll is local-only and does no patient/network writes.
[{call ACME_fnc_junctionalGuiSyncTick}, 0.2, []] call CBA_fnc_addPerFrameHandler;
