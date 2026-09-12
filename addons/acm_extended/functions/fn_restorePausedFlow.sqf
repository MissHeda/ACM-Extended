private _paused = missionNamespace getVariable ["ACME_infusion_pendingPausedFlow", []];
if (_paused isEqualTo []) exitWith {};

_paused params ["_patient", "_partIndex", "_iv", "_accessSite", "_oldFlow"];
ACME_infusion_pendingPausedFlow = nil;

if (isNull _patient || {_partIndex < 0} || {_oldFlow < 0}) exitWith {};

if (_iv) then {
    private _flowArray = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IV", [[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1]]]);
    if (_partIndex < count _flowArray) then {
        private _partFlow = +(_flowArray select _partIndex);
        if (_accessSite >= 0 && {_accessSite < count _partFlow}) then {
            _partFlow set [_accessSite, _oldFlow];
            _flowArray set [_partIndex, _partFlow];
            [_patient, [["fluidBagsFlowIV", _flowArray]], true] call ACM_circulation_fnc_setRuntimeState;
        };
    };
} else {
    private _flowArray = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IO", [1,1,1,1,1,1]]);
    if (_partIndex < count _flowArray) then {
        _flowArray set [_partIndex, _oldFlow];
        [_patient, [["fluidBagsFlowIO", _flowArray]], true] call ACM_circulation_fnc_setRuntimeState;
    };
};
