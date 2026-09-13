// Persistent AAJT-S device rows. The row follows the actual compressed territory and remains on dead casualties.
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN < 0}) exitWith {};
private _p = (["head","body","leftarm","rightarm","leftleg","rightleg"]) param [_selectionN, ""];
if (_p == "") exitWith {};
private _col = [1.0, 0.55, 0.10, 1];
switch (_p) do {
    case "body": {
        if (_target getVariable ["ACME_AAJT_zone3", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] Zone 3 REBOA %1", _target getVariable ["ACME_AAJT_zone3At", ""]], _col];
        };
    };
    case "leftleg";
    case "rightleg": {
        if (_target getVariable ["ACME_AAJT_zone3", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] Zone 3 REBOA %1", _target getVariable ["ACME_AAJT_zone3At", ""]], _col];
        };
        if ((_target getVariable ["ACME_AAJT_inguinal", false]) && {(_target getVariable ["ACME_AAJT_inguinalSide", ""]) == _p}) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] Inguinal %1", _target getVariable ["ACME_AAJT_inguinalAt", ""]], _col];
        };
    };
    case "leftarm": {
        if (_target getVariable ["ACME_AAJT_axillaleft", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] Axilla %1", _target getVariable ["ACME_AAJT_axillaleftAt", ""]], _col];
        };
    };
    case "rightarm": {
        if (_target getVariable ["ACME_AAJT_axillaright", false]) then {
            _woundEntries pushBack [format ["AAJT-S [NAR] Axilla %1", _target getVariable ["ACME_AAJT_axillarightAt", ""]], _col];
        };
    };
};
