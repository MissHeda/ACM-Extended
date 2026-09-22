// Give the pose the casualty returns to after Semi-Fowler is lowered or suspended.
//
// Hard invariant: Semi-Fowler is a supine posture. Its exit/rest state is therefore always the project's stable
// face-up lying state. Never replay a cached face-down/prone animation from before elevation.
params [["_patient", objNull, [objNull]]];

private _faceUp = missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"];
if !(_faceUp isEqualType "") then {_faceUp = "ACM_LyingState";};
if (_faceUp == "" || {!isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _faceUp)}) then {
    _faceUp = "ACM_LyingState";
};
_faceUp
