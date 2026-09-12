/*
 * Select an established external jugular in ACM's transfusion menu.
 * Site 0 = patient-left EJ, site 1 = patient-right EJ.
 */
params [["_site", 0]];

private _display = findDisplay 86000;
if (isNull _display) exitWith {};

private _patient = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
if (isNull _patient) exitWith {};

_site = (_site max 0) min 1;

private _ivArr = _patient getVariable ["ACM_circulation_IV_Placement", []];
private _hasSite = false;
if ((_ivArr isEqualType []) && {count _ivArr > 0}) then {
    private _head = _ivArr select 0;
    if (_head isEqualType []) then {
        private _v = _head param [_site, 0];
        _hasSite = (_v isEqualType 0) && {_v > 0};
    };
};
if (!_hasSite) exitWith {};

[["transfusionSelectIV", true], ["transfusionSelectedBodyPart", "head"], ["transfusionSelectedAccessSite", _site]] call ACM_circulation_fnc_setLocalUiState;

call ACM_circulation_fnc_TransfusionMenu_UpdateSelection;
[false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList;

// the selection label of ACM only knows upper, middle and lower. an ej is a head iv, so override the label after ACM
// updates it.
private _ctrlSelectionText = _display displayCtrl 86002;
if (!isNull _ctrlSelectionText) then {
    private _side = ["Left EJ", "Right EJ"] select _site;
    _ctrlSelectionText ctrlSetText format ["Head - IV (%1)", _side];
};

// force our layout and list signatures to refresh immediately after the body-part swap.
uiNamespace setVariable ["ACME_infusion_ActiveInfusionListSignature", ""];
uiNamespace setVariable ["ACME_infusion_PreparedListSignature", ""];
call ACME_fnc_updateTransfusionControls;
