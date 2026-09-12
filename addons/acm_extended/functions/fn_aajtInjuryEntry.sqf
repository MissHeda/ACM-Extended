// add an "AAJT-S [NAR] <time>" row to the medical-menu overview injury list for any part an AAJT-s is controlling.
// an inguinal, meaning body, placement reads on both legs, and an axilla placement reads on that arm. the time is
// the in-game time the device was applied, tccc-style, so the team can track the device time.
// it hooks ace_medical_gui_updateInjuryListWounds, which passes _woundEntries by reference.
// _this is [_ctrl, _target, _selectionN, _woundEntries, _bodyPartName].
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN < 0}) exitWith {};
private _p = (["head","body","leftarm","rightarm","leftleg","rightleg"]) param [_selectionN, ""];
if (_p == "") exitWith {};

private _col = [1.0, 0.55, 0.10, 1];  // amber. device / tourniquet line
switch (_p) do {
    case "leftleg";
    case "rightleg": {
        if (_target getVariable ["ACME_AAJT_inguinal", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] %1", _target getVariable ["ACME_AAJT_inguinalAt", ""]], _col];
        };
    };
    case "leftarm": {
        if (_target getVariable ["ACME_AAJT_axillaleft", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] %1", _target getVariable ["ACME_AAJT_axillaleftAt", ""]], _col];
        };
    };
    case "rightarm": {
        if (_target getVariable ["ACME_AAJT_axillaright", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] %1", _target getVariable ["ACME_AAJT_axillarightAt", ""]], _col];
        };
    };
    default {};
};
