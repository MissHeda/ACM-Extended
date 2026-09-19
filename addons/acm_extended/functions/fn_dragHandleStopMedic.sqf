// Local provider cleanup. Idempotent so both an owner stop event and the local watchdog can call it safely.
params [["_medic",objNull,[objNull]],["_patient",objNull,[objNull]],["_reason","manual",[""]],["_session","",[""]]];
if (isNull _medic || {!local _medic}) exitWith {};

private _currentSession = _medic getVariable ["ACME_dragHandle_session",""];
// A delayed stop from an older transaction must never tear down a newer harness session.
if (_session != "" && {_currentSession != ""} && {_session != _currentSession}) exitWith {};

private _pfh = _medic getVariable ["ACME_dragHandle_medicPFH",-1];
if (_pfh isEqualType 0 && {_pfh >= 0}) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
_medic setVariable ["ACME_dragHandle_medicPFH",-1];

if (!isNil "ace_common_fnc_statusEffect_set") then {
    [_medic,"blockSprint","ACME_dragHandle",false] call ace_common_fnc_statusEffect_set;
} else {
    _medic allowSprint true;
};

if (!isNil "ace_advanced_fatigue_setAnimExclusions") then {
    ace_advanced_fatigue_setAnimExclusions = ace_advanced_fatigue_setAnimExclusions - ["ACME_dragHandle"];
};

private _saved = _medic getVariable ["ACME_dragHandle_savedAnimCoef",1];
private _last = _medic getVariable ["ACME_dragHandle_lastAnimCoef",-1];
private _cur = getAnimSpeedCoef _medic;
// Restore only if our coefficient still owns the value. If another addon deliberately changed it while dragging,
// leave that newer value alone.
if (_last < 0 || {abs (_cur - _last) < 0.04}) then {
    _medic setAnimSpeedCoef _saved;
};

_medic setVariable ["ACME_dragHandle_patient",objNull,true];
if (_session != "") then {_medic setVariable ["ACME_dragHandle_lastStoppedSession",_session];};
_medic setVariable ["ACME_dragHandle_session",""];
_medic setVariable ["ACME_dragHandle_pending",false];
_medic setVariable ["ACME_dragHandle_stopPending",false];
_medic setVariable ["ACME_dragHandle_weight",nil];
_medic setVariable ["ACME_dragHandle_tension",nil];
_medic setVariable ["ACME_dragHandle_savedAnimCoef",nil];
_medic setVariable ["ACME_dragHandle_lastAnimCoef",nil];

if (_reason in ["overstretch","vehicle","dragger_unconscious","patient_awake","procedure","ace_transport","death","locality"]) then {
    private _msg = switch (_reason) do {
        case "overstretch": {"Drag handle released: tether overstretched."};
        case "vehicle": {"Drag handle released: vehicle transition."};
        case "dragger_unconscious": {"Drag handle released: dragger incapacitated."};
        case "patient_awake": {"Drag handle released: casualty regained consciousness."};
        case "procedure": {"Drag handle released: a procedure took over the casualty position."};
        case "ace_transport": {"Drag handle released: another transport action took over."};
        case "locality": {"Drag handle released: casualty ownership changed."};
        case "death": {"Drag handle released."};
        default {"Drag handle released."};
    };
    [_msg,1.8,_medic,12] call ace_common_fnc_displayTextStructured;
};
