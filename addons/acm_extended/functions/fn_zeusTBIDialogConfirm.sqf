// the confirm handler for ACME_TBIModule_Dialog. it reads the chosen severity, from the slider, and the initial
// state, from the combo, and applies a TBI to the stashed target through ACME_fnc_tbiInit, routed to the owner of
// the unit.
// the state presets, by combo index, are:
// 0 mild, at severity 0.20, with a normal ICP and no herniation.
// 1 moderate, at severity 0.50, with a mildly raised ICP.
// 2 severe, at severity 0.80, with a raised ICP.
// 3 herniating, at severity 0.90, with a high ICP and the herniation cascade armed.
// the severity slider overrides the severity of the preset, and the preset sets the ICP and herniation posture.
disableSerialization;
private _display = findDisplay 87500;
if (isNull _display) exitWith {};

private _unit = uiNamespace getVariable ["ACME_TBIModule_target", objNull];
if (isNull _unit || {!alive _unit}) exitWith {
    _display closeDisplay 2;
    ["TBI module: target no longer valid.", 2] call ace_common_fnc_displayTextStructured;
};

private _sev  = sliderPosition 87501;
private _state = lbCurSel 87502;
if (_state < 0) then { _state = 1; };

_display closeDisplay 1;

// apply it where the unit is local.
if (local _unit) then {
    [_unit, _sev, _state] call ACME_fnc_zeusTBIApplyLocal;
} else {
    [_unit, _sev, _state] remoteExec ["ACME_fnc_zeusTBIApplyLocal", _unit];
};

private _names = ["Mild", "Moderate", "Severe", "Herniating"];
[format ["TBI applied to %1: %2 (severity %3).", name _unit, (_names param [_state, "Moderate"]), (_sev toFixed 2)], 2.5] call ace_common_fnc_displayTextStructured;
