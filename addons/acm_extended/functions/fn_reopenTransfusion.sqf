/* Local return after the source dialog has unloaded. Never replace a newer dialog. */
params ["_return"];
_return params ["_medic", "_patient", "_part", ["_iv", true], ["_site", -1]];
if (isNull _patient || {isNull _medic}) exitWith {};
ace_medical_gui_pendingReopen = false;
[{
    params ["_medic", "_patient", "_part", "_iv", "_site"];
    if (isNull _patient || {isNull _medic} || {!alive _medic} || {dialog}) exitWith {};
    if (!isNull (findDisplay 84000) || {!isNull (findDisplay 86200)}) exitWith {};
    [_medic, _patient, _part] call ACM_circulation_fnc_openTransfusionMenu;
    private _d = findDisplay 86000;
    if (isNull _d) exitWith {};
    private _valid = if (_iv) then {
        _site >= 0 && {[_patient, _part, 0, _site] call ACM_circulation_fnc_hasIV}
    } else {[_patient, _part, 0] call ACM_circulation_fnc_hasIO};
    if (_valid) then {
        ACM_circulation_TransfusionMenu_SelectIV = _iv;
        ACM_circulation_TransfusionMenu_Selected_AccessSite = _site;
        call ACM_circulation_fnc_TransfusionMenu_UpdateSelection;
        [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList;
    };
}, [_medic, _patient, _part, _iv, _site], 0.15] call CBA_fnc_waitAndExecute;
