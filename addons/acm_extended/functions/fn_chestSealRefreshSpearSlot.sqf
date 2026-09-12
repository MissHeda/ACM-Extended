disableSerialization;
private _display = uiNamespace getVariable ["ACME_CS_DLG", displayNull];
if (isNull _display) exitWith {};
private _n = uiNamespace getVariable ["ACME_CS_SpearsLeft", 0];
private _held = uiNamespace getVariable ["ACME_CS_SpearHeld", false];
private _logo = _display displayCtrl 86432;
private _cnt = _display displayCtrl 86433;
_logo ctrlSetText "\acm_extended\ui\items\nar_spear_ca.paa";
[_logo, _held, _n] call ACME_fnc_traySlotState;
if (_held) then {
    _cnt ctrlSetText "IN HAND";
} else {
    _cnt ctrlSetText (if (_n > 0) then {format ["x%1", _n]} else {"EMPTY"});
};
