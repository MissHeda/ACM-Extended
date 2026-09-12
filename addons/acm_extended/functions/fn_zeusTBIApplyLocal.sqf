// this runs where the target is local. it applies a fresh TBI at the chosen severity, then shapes the initial ICP and
// herniation posture from the state preset, where 0 is mild, 1 moderate, 2 severe and 3 herniating.
// call or remoteexec it as [_unit, _severity from 0 to 1, _state from 0 to 3] call ACME_fnc_zeusTBIApplyLocal.
params ["_unit", ["_sev", 0.5], ["_state", 1]];
if (isNull _unit || {!alive _unit} || {!local _unit}) exitWith {};

private _tbi = [_unit, _sev, true] call ACME_fnc_tbiInit;  // _force = true: fresh injury at this severity
if (isNil "_tbi") exitWith {};

private _baseICP = missionNamespace getVariable ["ACME_tbi_baseICP", 10];
private _hernICP = missionNamespace getVariable ["ACME_tbi_herniationICP", 30];
switch (_state) do {
    case 0: { _tbi set ["icp", _baseICP]; };  // mild
    case 1: { _tbi set ["icp", _baseICP + 5]; };  // moderate
    case 2: { _tbi set ["icp", _hernICP - 3]; };  // severe, near the herniation trigger
    case 3: {  // herniating: armed cascade
        _tbi set ["icp", _hernICP + 5];
        _tbi set ["herniating", true];
        _tbi set ["herniationClock", missionNamespace getVariable ["ACME_tbi_herniationStageSeconds", 360]];
        _tbi set ["herniationStage", 1];
        _tbi set ["pupils", 1];
    };
};
[_unit, _tbi] call ACME_fnc_tbiStateCommit;
