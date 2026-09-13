// the junctional wound and wrap body-image overlays.
// it is the same proven pattern as the NRB-mask overlay: we do not config-merge into ACM's
// ace_medical_gui_BodyImage, because that drops the inherited silhouette and blanks the whole image.
// instead we listen on ACM's own draw event, "ace_medical_gui_updateBodyImage", and create the overlay controls at
// runtime, parented to the live control group, cloning the position of torso_io, idc 70113. every ACM body icon
// clones that full-image rect, and each per-limb texture paints its mark at the correct spot, so the position is
// automatic.
// on layering: runtime-created controls render on top of ACM's config icons. arma has no runtime z-reorder and a
// config-merge blanks the image, so the wraps cannot be forced beneath ACM's icons. on a wrapped limb the wrap
// will sit over any iv, io or tourniquet icon there. see the readme note.
// the state per limb is _target getvariable ["ACME_Junc_<part>", ""], which is "", "open", "packed" or "wrapped".
// open and packed show the open-wound icon, meaning still bleeding and not yet secured.
// wrapped shows the wrap icon, meaning healed and secured, and hides the open-wound icon.

params ["_ctrlGroup", "_target"];
if (isNull _ctrlGroup) exitWith {};

private _ref = _ctrlGroup controlsGroupCtrl 70113;  // idc_body_torso_io, the full-image rect all the icons clone.

// the part, the wrapidc, the woundidc, the wraptexture and the woundtexture.
private _limbs = [
    ["leftarm",  7290000, 7290004, "junctionalwrap_leftarm_ca.paa",  "junctionalwound_leftarm_ca.paa"],
    ["rightarm", 7290001, 7290005, "junctionalwrap_rightarm_ca.paa", "junctionalwound_rightarm_ca.paa"],
    ["leftleg",  7290002, 7290006, "junctionalwrap_leftleg_ca.paa",  "junctionalwound_leftleg_ca.paa"],
    ["rightleg", 7290003, 7290007, "junctionalwrap_rightleg_ca.paa", "junctionalwound_rightleg_ca.paa"]
];

// israeli pressure bandage olive green. the wrap depicts a physical bandage rather than a status, so it no longer
// borrows the shared warning yellow, which stays untouched for the systems that use it semantically.
private _wrapColor = missionNamespace getVariable ["ACME_junctionalWrapColor", [0.38, 0.42, 0.28, 1]];

{
    _x params ["_part", "_wrapIdc", "_woundIdc", "_wrapTex", "_woundTex"];

    private _state = if (isNull _target) then { "" } else { _target getVariable [format ["ACME_Junc_%1", _part], ""] };

    // the wrap control. it is created first so it sits below the open-wound control, and they never co-show anyway.
    private _wrapC = _ctrlGroup controlsGroupCtrl _wrapIdc;
    if (isNull _wrapC) then {
        _wrapC = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", _wrapIdc, _ctrlGroup];
        if (!isNull _ref) then { _wrapC ctrlSetPosition (ctrlPosition _ref); };
        _wrapC ctrlSetText ("\acm_extended\ui\items\" + _wrapTex);
        _wrapC ctrlSetTextColor _wrapColor;  // tint the wrap to cream, because the art is ours to color.
        _wrapC ctrlCommit 0;
    };

    // the open-wound control, rendered as the artist drew it, with no tint.
    private _woundC = _ctrlGroup controlsGroupCtrl _woundIdc;
    if (isNull _woundC) then {
        _woundC = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", _woundIdc, _ctrlGroup];
        if (!isNull _ref) then { _woundC ctrlSetPosition (ctrlPosition _ref); };
        _woundC ctrlSetText ("\acm_extended\ui\items\" + _woundTex);
        _woundC ctrlCommit 0;
    };

    // Reapply position/texture on every body-image update. ACE can rebuild/reflow the body group during an active
    // treatment; relying only on creation-time properties made the packed wound disappear until the menu reopened.
    if (!isNull _ref) then {
        _woundC ctrlSetPosition (ctrlPosition _ref);
        _wrapC ctrlSetPosition (ctrlPosition _ref);
    };
    _woundC ctrlSetText ("\acm_extended\ui\items\" + _woundTex);
    _wrapC ctrlSetText ("\acm_extended\ui\items\" + _wrapTex);
    _woundC ctrlCommit 0;
    _wrapC ctrlCommit 0;
    _woundC ctrlShow (_state in ["open", "packed", "xstat"]);
    _wrapC  ctrlShow (_state == "wrapped");
} forEach _limbs;

// the NAR AAJT-s overlays.
// they are created after the wound and wrap controls, and being runtime controls they sit above all of ACM's config
// icons, the iv, io and tourniquet and the AED pads, so the device always sits on top, as required. the inguinal
// one sits over the groin and the axilla icons sit over each armpit. they are shown from the per-placement flags
// set by fn_aajtapply.
private _aajt = [
    [7290010, "aajt-s_inguinal_ca.paa",      (!isNull _target && {_target getVariable ["ACME_AAJT_inguinal",   false]})],
    [7290011, "aajt-s_axilla_left_ca.paa",   (!isNull _target && {_target getVariable ["ACME_AAJT_axillaleft",  false]})],
    [7290012, "aajt-s_axilla_right_ca.paa",  (!isNull _target && {_target getVariable ["ACME_AAJT_axillaright", false]})],
    [7290013, "aajt-s_zone3_reboa_ca.paa",   (!isNull _target && {_target getVariable ["ACME_AAJT_zone3",       false]})]
];
{
    _x params ["_idc", "_tex", "_on"];
    private _c = _ctrlGroup controlsGroupCtrl _idc;
    if (isNull _c) then {
        _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", _idc, _ctrlGroup];
        if (!isNull _ref) then { _c ctrlSetPosition (ctrlPosition _ref); };
        _c ctrlSetText ("\acm_extended\ui\items\" + _tex);
        _c ctrlCommit 0;
    };
    _c ctrlShow _on;
} forEach _aajt;
