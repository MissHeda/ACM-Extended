/* B52 pulse palpation minigame.
 * Keeps ACM's pulse visual, but owns Escape explicitly and uses the requested provider pose:
 * AinvPknlMstpSnonWrflDnon_medic1 -> freeze at exactly 0.691 s -> clean crouched exit.
 */
params ["_medic","_patient","_bodyPart"];
if (isNull _medic || {isNull _patient}) exitWith {};
private _site = switch (toLower _bodyPart) do {
    case "head": {"carotid pulse"};
    case "leftarm"; case "rightarm": {"radial pulse"};
    default {"femoral pulse"};
};
// Vehicle-safe path. Closing the medical dialog and forcing the kneeling pulse minigame while seated makes the
// engine immediately tear the interaction down. If both units share the same non-null vehicle, perform the same
// authoritative pulse read directly and leave the medical UI open. Different vehicle contexts remain out of reach.
private _medicVehicle = objectParent _medic;
private _patientVehicle = objectParent _patient;
if (!isNull _medicVehicle || {!isNull _patientVehicle}) exitWith {
    if (_medicVehicle isNotEqualTo _patientVehicle || {isNull _medicVehicle}) then {
        ["Patient is out of reach.", 1.5, _medic] call ace_common_fnc_displayTextStructured;
    } else {
        [_patient,"activity","%1 felt for a %2",[[_medic,false,true] call ace_common_fnc_getName,_site]] call ace_medical_treatment_fnc_addToLog;
        [_medic, _patient, _bodyPart] call ace_medical_treatment_fnc_checkPulseLocal;
    };
};

[_patient,"activity","%1 felt for a %2",[[_medic,false,true] call ace_common_fnc_getName,_site]] call ace_medical_treatment_fnc_addToLog;
ace_medical_gui_pendingReopen = false;
if (dialog) then {closeDialog 0;};
"ACM_FeelPulse" cutRsc ["RscFeelPulse","PLAIN",0,false];
private _disp = uiNamespace getVariable ["ACM_FeelPulse",displayNull];
if (!isNull _disp) then {(_disp displayCtrl 80001) ctrlSetText format ["%1 (%2)",[_patient,false,true] call ace_common_fnc_getName,_site];};
uiNamespace setVariable ["ACME_PulseCheckActive",true];
uiNamespace setVariable ["ACME_PulseCheckEscape",false];
private _epoch = [_medic,"pulse",-1] call ACME_fnc_treatmentPoseStart;
uiNamespace setVariable ["ACME_PulsePoseEpoch",_epoch];
// Consume Escape instead of letting the engine open the pause menu. The RscFeelPulse layer is a cutRsc, not a
// dialog, so the main display (46) must own the KeyDown as well as CBA's key handler.
private _mainDisplay = findDisplay 46;
private _escEH = -1;
if (!isNull _mainDisplay) then {
    _escEH = _mainDisplay displayAddEventHandler ["KeyDown", {
        params ["", "_key"];
        if (_key != 1 || {!(uiNamespace getVariable ["ACME_PulseCheckActive", false])}) exitWith {false};
        uiNamespace setVariable ["ACME_PulseCheckEscape", true];
        true
    }];
};
private _esc = [1,[false,false,false],{
    if (uiNamespace getVariable ["ACME_PulseCheckActive", false]) then {
        uiNamespace setVariable ["ACME_PulseCheckEscape",true];
        true
    } else {false};
},"keydown","",false,0] call CBA_fnc_addKeyHandler;
uiNamespace setVariable ["ACME_PulseEscKey",_esc];
uiNamespace setVariable ["ACME_PulseEscEH",_escEH];

[{
    params ["_args","_pfh"];
    _args params ["_medic","_patient","_bodyPart","_esc","_epoch","_mainDisplay","_escEH"];
    private _quit = isNull _medic || {isNull _patient} || {!alive _medic} || {_medic getVariable ["ACE_isUnconscious",false]} || {uiNamespace getVariable ["ACME_PulseCheckEscape",false]} || {_medic distance2D _patient > 4.5};
    if (_quit) exitWith {
        [_pfh] call CBA_fnc_removePerFrameHandler;
        [_esc,"keydown"] call CBA_fnc_removeKeyHandler;
        if (!isNull _mainDisplay && {_escEH >= 0}) then {_mainDisplay displayRemoveEventHandler ["KeyDown", _escEH];};
        "ACM_FeelPulse" cutText ["","PLAIN",0,false];
        uiNamespace setVariable ["ACME_PulseCheckActive",false];
        [_medic,"pulse",_epoch] call ACME_fnc_treatmentPoseStop;
        if (uiNamespace getVariable ["ACME_PulseCheckEscape",false]) then {[_patient,"examine"] call ACME_fnc_reopenMedicalMenu;};
    };
    private _disp = uiNamespace getVariable ["ACM_FeelPulse",displayNull];
    if (isNull _disp) exitWith {};
    private _heart = _disp displayCtrl 80002;
    private _hr = if (alive _patient && {[_patient] call ACM_circulation_fnc_hasPulse} && {!([_patient,_bodyPart] call ace_medical_treatment_fnc_hasTourniquetAppliedTo)}) then {_patient getVariable ["ace_medical_heartRate",80]} else {0};
    private _next = uiNamespace getVariable ["ACME_PulseVisualNext",0];
    if (_hr > 0) then {
        _heart ctrlShow true;
        if (CBA_missionTime >= _next) then {
            private _base = _heart getVariable ["ACME_PulseBase",ctrlPosition _heart]; _heart setVariable ["ACME_PulseBase",_base];
            _base params ["_x","_y","_w","_h"];
            private _s = 1.7; private _cx=_x+_w/2; private _cy=_y+_h/2;
            _heart ctrlSetPosition [_cx-_w*_s/2,_cy-_h*_s/2,_w*_s,_h*_s]; _heart ctrlCommit 0.12;
            [{params ["_c","_b"]; if (!isNull _c) then {_c ctrlSetPosition _b; _c ctrlCommit 0.18;};},[_heart,_base],0.12] call CBA_fnc_waitAndExecute;
            uiNamespace setVariable ["ACME_PulseVisualNext",CBA_missionTime + (60 / (_hr max 1))];
        };
    } else {_heart ctrlShow false;};
},0,[_medic,_patient,_bodyPart,_esc,_epoch,_mainDisplay,_escEH]] call CBA_fnc_addPerFrameHandler;
