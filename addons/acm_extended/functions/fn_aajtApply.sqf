/* Apply an AAJT-S at the selected anatomical site. Body is Zone 3 REBOA; legs are unilateral inguinal;
   arms are unilateral axillary. Native wound/IV/IO/medication behavior reads ACME_fnc_aajtOccludes. */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
_patient setVariable ["ACME_Junc_AAJTApplying", [], true];
private _p = toLowerANSI _bodyPart;
private _two = {private _n = floor _this; if (_n < 10) then {"0" + str _n} else {str _n}};
private _d = daytime; private _hh = floor _d; private _mm = (_d - _hh) * 60; private _ss = (_mm - floor _mm) * 60;
private _atStr = format ["%1:%2:%3", _hh call _two, _mm call _two, _ss call _two];
private _site = "";
switch (_p) do {
    case "body": {
        [_patient, "zone3", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "leftleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient, "rightleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient] call ACME_fnc_aajtDownedTick;
        _site = "Zone 3 REBOA";
        ["AAJT-S applied: Zone 3 REBOA.", 3] call ace_common_fnc_displayTextStructured;
    };
    case "leftleg";
    case "rightleg": {
        [_patient, "inguinal", [true, _atStr, _p]] call ACME_fnc_aajtStateCommit;
        [_patient, _p, true] call ACME_fnc_aajtSetLegTQ;
        _site = format ["%1 inguinal", if (_p == "leftleg") then {"left"} else {"right"}];
        [format ["AAJT-S applied: %1.", _site], 3] call ace_common_fnc_displayTextStructured;
    };
    case "leftarm": {
        [_patient, "leftarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "leftarm", true] call ACME_fnc_aajtSetLegTQ;
        _site = "left axilla";
        ["AAJT-S applied: left axilla.", 3] call ace_common_fnc_displayTextStructured;
    };
    case "rightarm": {
        [_patient, "rightarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "rightarm", true] call ACME_fnc_aajtSetLegTQ;
        _site = "right axilla";
        ["AAJT-S applied: right axilla.", 3] call ace_common_fnc_displayTextStructured;
    };
    default {};
};
if (_site == "") exitWith {};
[_patient] call ACME_fnc_aajtPainTick;
[_patient, "activity", "%1 applied an AAJT-S (%2)", [[_medic, false, true] call ace_common_fnc_getName, _site]] call ace_medical_treatment_fnc_addToLog;
