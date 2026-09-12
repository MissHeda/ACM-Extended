/* Live shared pool, updated only on native events or actual suction debits. */
params ["_patient"];
if (isNull _patient) exitWith {};
private _state = [_patient] call ACME_fnc_laryngoFluidState;
private _previous = uiNamespace getVariable ["ACME_laryngo_fluidSeen", []];
if (_state isEqualTo _previous) exitWith {};
uiNamespace setVariable ["ACME_laryngo_fluidSeen", _state];
_state params ["_stamp", "_kind", "_target"];
if (_kind == "" || {_target <= 0}) exitWith {
    uiNamespace setVariable ["ACME_laryngo_fluidKind", ""];
    uiNamespace setVariable ["ACME_laryngo_fluidStage", 0];
    uiNamespace setVariable ["ACME_laryngo_fluidMode", "rest"];
};
private _firstView = count _previous != 3;
private _newEpisode = _firstView;
if (!_newEpisode) then {_newEpisode = !((_previous select 0) isEqualTo _stamp);};
// Opening a view reveals retained contents. Only a new vomit identity observed
// during this view represents active emesis; unrelated blood/secretions changes do not.
private _newVomit = false;
if (!_firstView && {_kind == "v"}) then {
    private _oldStamp = _previous select 0;
    _newVomit = (_previous select 1) != "v"
        || {(_oldStamp param [0, 0]) != (_stamp param [0, 0])}
        || {!((_oldStamp param [2, []]) isEqualTo (_stamp param [2, []]))};
};
private _canEmesis = alive _patient
    && {!(_patient getVariable ["ace_medical_inCardiacArrest", false])}
    && {!(_patient getVariable ["ACME_roc_paralyzed", false])};
private _current = uiNamespace getVariable ["ACME_laryngo_fluidStage", 0];
uiNamespace setVariable ["ACME_laryngo_fluidKind", _kind];
uiNamespace setVariable ["ACME_laryngo_fluidCap", _target];
// A debit is the exact remaining pool, not a new fill animation. No observer can refill it.
if (_firstView || {!_newEpisode} || {_current > _target} || {_kind == "v" && {!_newVomit || {!_canEmesis}}}) then {
    _current = _target;
    uiNamespace setVariable ["ACME_laryngo_fluidStage", _current];
};
uiNamespace setVariable ["ACME_laryngo_fluidMode", if (_current < _target) then {"fill"} else {"rest"}];
uiNamespace setVariable ["ACME_laryngo_fluidFillNext", 0];
uiNamespace setVariable ["ACME_laryngo_fluidPhaseNext", 0];
if (_newVomit && {_canEmesis}) then {uiNamespace setVariable ["ACME_laryngo_ejectedThisVomit", false];};
