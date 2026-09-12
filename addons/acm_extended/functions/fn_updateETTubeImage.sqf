// the et tube marker on the body diagram of the medical menu.
// like the ej, junctional and AAJT overlays, the et tube art is a full-canvas overlay: the tube is pre-painted at the
// correct, airway, spot in the same canvas the body image of ACM uses, so we simply clone the full body-image rect,
// idc 70113, and toggle the visibility. there is no manual positioning.
// there are two states. secured means ACME_ETT_Inserted is true and it is secured, which is the normal intubated
// state. unsecured means a tube is placed and not yet secured, ACME_ETT_Unsecured, if that state is ever set.
// only one shows at a time.
params ["_ctrlGroup", "_target"];
if (isNull _ctrlGroup) exitWith {};

private _ref = _ctrlGroup controlsGroupCtrl 70113;  // full body-image rect all icons clone
if (isNull _ref) exitWith {};
private _refPos = ctrlPosition _ref;

private _inserted  = false;
private _unsecured = false;
if (!isNull _target) then {
    _inserted  = _target getVariable ["ACME_ETT_Inserted", false];
    _unsecured = _target getVariable ["ACME_ETT_Unsecured", false];
};
// secured shows only when it is inserted and not flagged unsecured.
private _showSecured   = _inserted && {!_unsecured};
private _showUnsecured = _inserted && _unsecured;

{
    _x params ["_idc", "_tex", "_show"];
    private _c = _ctrlGroup controlsGroupCtrl _idc;
    if (isNull _c) then {
        _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", _idc, _ctrlGroup];
        _c ctrlSetText _tex;
        // match the airway icons of ACM, where the head_opa, NPA, igel and surgicalairway all use colortext
        // {0.19,0.91,0.93,1}, so the et tube reads as the same blue airway marker as every other adjunct on the body
        // diagram.
        _c ctrlSetTextColor [0.19, 0.91, 0.93, 1];
        _c ctrlSetPosition _refPos;  // full-canvas clone, pixel-aligned to the diagram
        _c ctrlCommit 0;
    };
    _c ctrlShow _show;
} forEach [
    [7290030, "\acm_extended\ui\items\et_tube_secured_ca.paa",   _showSecured],
    [7290031, "\acm_extended\ui\items\et_tube_unsecured_ca.paa", _showUnsecured]
];
