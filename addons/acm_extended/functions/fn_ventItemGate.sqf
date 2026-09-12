/* Local panel gate. Service access belongs to this panel and patient.
   fn_ventPanelNavClick.sqf retains display-only calibration and software-update actions. */
params ["_kind", ["_label", "this setting"]];
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith { false };
private _target = uiNamespace getVariable ["ACME_vent_target", ACE_player];
private _venting = !isNull _target
    && {_target getVariable ["ACME_vent_connected", false]}
    && {_target getVariable ["ACME_vent_driving", false]};
if (_kind in ["gray", "red"] && {_venting}) exitWith {
    _dlg setVariable ["ACME_vent_itemConfirmed", []];
    [format ["%1 is unavailable while ventilating. Stop ventilation first.", _label], 2] call ace_common_fnc_displayTextStructured;
    false
};
private _code = missionNamespace getVariable ["ACME_vent_techCode", "0000"];
if (_kind isEqualTo "red" && {!(_code isEqualType "")}) exitWith {
    ["The mission technician code must be a string.", 2] call ace_common_fnc_displayTextStructured;
    false
};
private _unlocked = (_dlg getVariable ["ACME_vent_techUnlocked", false])
    && {(_dlg getVariable ["ACME_vent_techAuthCode", ""]) isEqualTo _code}
    && {(_dlg getVariable ["ACME_vent_techAuthTarget", objNull]) isEqualTo _target};
if (_kind isEqualTo "red" && {_code != ""} && {!_unlocked}) exitWith {
    _dlg setVariable ["ACME_vent_itemConfirmed", []];
    [_label] call ACME_fnc_ventTechPrompt;
    false
};
if (_kind in ["yellow", "red"]) exitWith {
    private _request = [_label, _target];
    private _confirmed = _dlg getVariable ["ACME_vent_itemConfirmed", []];
    if (_confirmed isEqualTo _request) exitWith {
        _dlg setVariable ["ACME_vent_itemConfirmed", []];
        true
    };
    _dlg setVariable ["ACME_vent_itemConfirmed", _request];
    [format ["%1: press again to confirm.", _label], 2] call ace_common_fnc_displayTextStructured;
    false
};
true
