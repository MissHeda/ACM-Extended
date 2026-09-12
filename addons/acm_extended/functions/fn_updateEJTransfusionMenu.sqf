private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
/*
 * Add EJ IV overlay icons + click targets to ACM's transfusion menu.
 * The EJ textures are full-body overlay canvases, not standalone cropped icons.
 * Draw them over the same body rect as ACM's body diagram, then place a small transparent
 * click target over the visible catheter/hub itself.
 */
private _display = findDisplay 86000;
if (isNull _display) exitWith {};

private _patient = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
private _leftEJ = false;
private _rightEJ = false;

if (!isNull _patient) then {
    private _ivArr = _patient getVariable ["ACM_circulation_IV_Placement", []];
    if ((_ivArr isEqualType []) && {count _ivArr > 0}) then {
        private _head = _ivArr select 0;
        if (_head isEqualType []) then {
            private _l = _head param [0, 0];
            private _r = _head param [1, 0];
            _leftEJ  = (_l isEqualType 0) && {_l > 0};
            _rightEJ = (_r isEqualType 0) && {_r > 0};
        };
    };
};

// the bodybackground position of the ACM transfusionmenu_dialog. no stock idc exists, so reproduce the stock
// rect.
private _bodyX = _uiX + (_uiW / 2) - (_uiW / 8);
private _bodyY = safeZoneY + (safeZoneH / 2) - (safeZoneH / 4.5);
private _bodyW = _uiW / 4;
private _bodyH = safeZoneH / 2;
private _bodyRect = [_bodyX, _bodyY, _bodyW, _bodyH];

private _selectedPart = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart", ""];
private _selectedIV = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_SelectIV", true];
private _selectedSite = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_AccessSite", -1];

private _getHotspotRect = {
    params ["_site"];
    // site 0 is the patient-left ej, shown screen-right on the front body diagram.
    private _cx = [0.573, 0.435] select _site;
    private _cy = 0.158;
    private _w = _bodyW * 0.050;
    private _h = _bodyH * 0.036;
    [
        _bodyX + (_bodyW * _cx) - (_w / 2),
        _bodyY + (_bodyH * _cy) - (_h / 2),
        _w,
        _h
    ]
};

private _makeIcon = {
    params ["_idc", "_tex", "_show", "_selected"];
    private _c = _display displayCtrl _idc;
    if (isNull _c) then {
        _c = _display ctrlCreate ["RscPicture", _idc];
    };
    _c ctrlSetText _tex;
    _c ctrlSetPosition _bodyRect;
    private _ejCol = if (_selected) then {[1, 1, 1, 1]} else {["success2", 1] call ACME_fnc_a11yColor};
    _c ctrlSetTextColor _ejCol;
    _c ctrlCommit 0;
    _c ctrlShow _show;
};

private _makeHotspot = {
    params ["_idc", "_site", "_show"];
    private _b = _display displayCtrl _idc;
    if (isNull _b) then {
        _b = _display ctrlCreate ["ACME_EJTransfusionHotspot", _idc];
        _b ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            [_ctrl getVariable ["ACME_EJTransfusionSite", 0]] call ACME_fnc_selectEJTransfusionSite;
        }];
    };
    _b setVariable ["ACME_EJTransfusionSite", _site];
    _b ctrlSetPosition ([_site] call _getHotspotRect);
    _b ctrlSetTooltip (["Left EJ", "Right EJ"] select _site);
    _b ctrlCommit 0;
    _b ctrlEnable _show;
    _b ctrlShow _show;
};

private _leftSelected = _selectedIV && {_selectedPart == "head"} && {_selectedSite == 0};
private _rightSelected = _selectedIV && {_selectedPart == "head"} && {_selectedSite == 1};

[7290120, "\acm_extended\ui\iv\iv_ej_left_ca.paa",  _leftEJ,  _leftSelected] call _makeIcon;
[7290121, "\acm_extended\ui\iv\iv_ej_right_ca.paa", _rightEJ, _rightSelected] call _makeIcon;
[7290122, 0, _leftEJ] call _makeHotspot;
[7290123, 1, _rightEJ] call _makeHotspot;

// the transfusion menu header, IDC 86002.
// ACM builds it in fnc_TransfusionMenu_UpdateSelection.sqf:25 as "<part> - IV (<Upper|Middle|Lower>)" and never
// switches the site on the descriptor setting. the head and EJ case was already handled here; the limbs were
// not, so a medic in hardcore picked "16g IV (Cephalic)" off a button and then read "Left Arm - IV (Lower)"
// at the top of the transfusion menu for the same line.
if (_selectedIV && {_selectedPart == "head"}) then {
    private _ctrlSelectionText = _display displayCtrl 86002;
    if (!isNull _ctrlSelectionText) then {
        private _side = ["Left EJ", "Right EJ"] select ((_selectedSite max 0) min 1);
        _ctrlSelectionText ctrlSetText format ["Head - IV (%1)", _side];
    };
};

if (_selectedIV
    && {_selectedPart in ["leftarm", "rightarm", "leftleg", "rightleg"]}
    && {((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true)}) then {
    private _ctrlSelectionText = _display displayCtrl 86002;
    if (!isNull _ctrlSelectionText) then {
        private _name = [_selectedPart, ((_selectedSite max 0) min 2), false] call ACME_fnc_skSiteName;
        if (_name isNotEqualTo "") then {
            private _partName = if (isNil "ACM_core_fnc_getBodyPartString") then { _selectedPart } else {
                [_selectedPart] call ACM_core_fnc_getBodyPartString
            };
            _ctrlSelectionText ctrlSetText format ["%1 - IV (%2)", _partName, _name];
        };
    };
};
