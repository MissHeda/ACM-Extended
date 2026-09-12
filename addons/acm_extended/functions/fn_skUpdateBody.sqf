/* Refresh the captured patient through the medical menu's native renderer.
   ctrlShow on a group also shows its children, so this is the ONLY function allowed to re-show the captured body.
   This function has no treatment writes and sends no network events. */
disableSerialization;
params [["_display", displayNull], ["_force", false]];
if (isNull _display) exitWith {};
private _group = _display displayCtrl 84140;
if (isNull _group) exitWith {};
private _show = (uiNamespace getVariable ["ACME_SK_View", "syringe"]) == "body" && {
    !(uiNamespace getVariable ["ACME_SK_TagEditMode", false]) && {
        (_display getVariable ["ACME_SK_Return", []]) isEqualTo []
    }
};
private _wasShown = _display getVariable ["ACME_SK_BodyVisible", false];
if (_show != _wasShown) then {
    // A later ctrlShow true would undo every patient-specific visibility decision.
    _group ctrlShow _show;
    _display setVariable ["ACME_SK_BodyVisible", _show];
    if (_show) then {
        // Reset default-hidden and runtime overlays before the first visible update.
        // ACE medical_gui/script_component.hpp defines the six anatomical layer IDs.
        {
            _x ctrlShow ((ctrlIDC _x) in [6005,6010,6015,6020,6025,6030] || {
                (toLower (ctrlClassName _x)) == "background"
            });
        } forEach allControls _group;
        _force = true;
    };
};
if (!_show) exitWith {};
private _now = diag_tickTime; // Display-local refresh scheduling only.
if (!_force && {_now < (_display getVariable ["ACME_SK_NextBody", 0])}) exitWith {};
_display setVariable ["ACME_SK_NextBody", _now + 0.1];
private _patient = _display getVariable ["ACME_SK_ReturnPatient", objNull];
if (isNull _patient) then {_patient = ACE_player;};
[_group, _patient, -1] call ace_medical_gui_fnc_updateBodyImage;
