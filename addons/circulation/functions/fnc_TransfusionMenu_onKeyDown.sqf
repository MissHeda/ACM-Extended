/* B52: native ACM transfusion key handler + Escape return to the ACE medical menu. */
params ["", "_args"];
_args params ["_display", "_keyPressed", "_shiftState", "_ctrlState", "_altState"];
if (_keyPressed == 1) exitWith {
    private _patient = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target", objNull];
    closeDialog 0;
    [_patient, "medication"] call ACME_fnc_reopenMedicalMenu;
    true
};
switch (_keyPressed) do {
    case 2: {if !(ACM_circulation_TransfusionMenu_SelectIV) then {ACM_circulation_TransfusionMenu_SelectIV = true;}; ["",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 3: {if !(ACM_circulation_TransfusionMenu_SelectIV) then {ACM_circulation_TransfusionMenu_SelectIV = true;}; ["",1] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 4: {if !(ACM_circulation_TransfusionMenu_SelectIV) then {ACM_circulation_TransfusionMenu_SelectIV = true;}; ["",2] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 16: {[] call ACM_circulation_fnc_TransfusionMenu_ToggleIV;};
    case 18: {[] call ACM_circulation_fnc_TransfusionMenu_SwitchTargetInventory;};
    case 17: {["head",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 31: {["body",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 32: {["leftarm",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 30: {["rightarm",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 45: {["leftleg",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
    case 44: {["rightleg",0] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;};
};
false
