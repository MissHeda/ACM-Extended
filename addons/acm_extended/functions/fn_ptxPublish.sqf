/* Sole continuous canonical projection. Never disclose model state to providers. */
params ["_patient","_state",["_tension",false]];
if (isNull _patient || {!local _patient} || {count _state!=9}) exitWith {};
_state=+_state;
_state set [1,(_state select 1) max 0 min 32];
_state set [2,(_state select 2) max 0 min 1];
_state set [3,(_state select 3) max 0 min 86400];
_state set [4,(_state select 4) max 0 min 1];
_state set [5,(_state select 5) max 0 min 1];
_state set [8,(_state select 8) max 0 min (_state select 1)];
private _native=if (_tension) then {4} else {(_state select 1) min 4};
_state set [7,_native];
private _wasTension=_patient getVariable ["ACM_breathing_TensionPneumothorax_State",false];
private _oldAir=_patient getVariable ["ACM_breathing_Pneumothorax_State",0];
if !(_state isEqualTo (_patient getVariable ["ACME_ptx_state",[]])) then {
    [_patient,"ACME_ptx_state",_state] call ACME_fnc_setVarNet;
};
[_patient, [["pneumothorax", _native], ["tensionPneumothorax", _tension]], true] call ACM_breathing_fnc_setRuntimeState;
if (_tension && {!_wasTension || {isNil {_patient getVariable "ACM_breathing_TensionPneumothorax_Time"}}}) then {
    [_patient, [["tensionTime", CBA_missionTime]], true] call ACM_breathing_fnc_setRuntimeState;
};
if (!_tension) then {
    if (!isNil {_patient getVariable "ACM_breathing_TensionPneumothorax_Time"}) then {
        [_patient, [["clearTensionTime", true]], true] call ACM_breathing_fnc_setRuntimeState;
    };
    [_patient,"ACME_ptx_tensionSeverity",0] call ACME_fnc_setVarNet;
    // Native hardcore injury otherwise stays latched until full heal.
    [_patient, [["hardcorePneumothorax", false]], true] call ACM_breathing_fnc_setRuntimeState;
};
if (_native!=_oldAir || {_tension!=_wasTension}) then {[_patient] call ACM_breathing_fnc_updateLungState;};
