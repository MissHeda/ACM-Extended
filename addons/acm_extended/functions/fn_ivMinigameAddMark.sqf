// append a persistent iv mark to the patient, so it survives re-opening the limb, and re-render.
// call it as [_u, _v, _kind, _holeTex, _frame, _gauge, _missTime, _scale] call ACME_fnc_ivMinigameAddMark.
// _kind is "hub", "removed" or "miss". _gauge colors the hub art and sizes the miss bruise.
// _rot and _alpha are miss bruises only. they carry the per-bruise variance so a repaint reproduces the same
// mark rather than rolling a new one, which would make every bruise twitch on every render.
params ["_u", "_v", "_kind", ["_holeTex", ""], ["_frame", ""], ["_gauge", 0], ["_missTime", -1], ["_scale", 1], ["_rot", 0], ["_alpha", 1]];
if !([] call ACME_fnc_ivUiValid) exitWith {};
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
// The tier is upper, middle or lower, from proximal to distal. The EJ uses left or right.
// This value is the site of the PUNCTURE. It is not the site of the band.
// Element 10 below holds this value.
// fn_ivMinigamePullStop reads element 10. It selects the ACM access site to remove.
// CAUTION: A mark with the band site lets a medic pull one catheter and remove a different IV.
// The two callers of this function run immediately after a puncture.
// Therefore ACME_IV_InsSite is correct for both callers.
// The EJ stores "" in ACME_IV_InsSite. The EJ keeps its locked side in ACME_IV_Site.
private _site = toLower (uiNamespace getVariable ["ACME_IV_InsSite", ""]);
if (_site isEqualTo "") then { _site = toLower (uiNamespace getVariable ["ACME_IV_Site", ""]); };
if (!isNull _patient) then {
    private _marks = _patient getVariable ["ACME_IV_Marks", []];
    // element 10 is the site tier, stored so the extravasation check for whether this new iv is distal to a compromised
    // site can compare a canonical anatomical height across the front and rear views, which do not share a v
    // coordinate space.
    // Optional element 13 preserves the physical catheter rotation on every provider.
    // Existing marks default to zero when rendered. Bruise rotation remains element 11.
    _marks pushBack [_bp, _view, _u, _v, _kind, _holeTex, _frame, _gauge, _missTime, _scale, _site, _rot, _alpha, if (_kind == "hub") then {uiNamespace getVariable ["ACME_IV_InsAngle", 0]} else {0}];
    // the marks are the authoritative record of this limb, so they are broadcast and versioned.
    // two of the three writers used to omit the broadcast flag, so a stick made by one medic never left their own
    // machine. a second medic on the same limb saw a clean arm, and reopening the screen did not help them,
    // because there was nothing to read.
    // the version lets an open screen see the change without a reopen. see the poll in fn_ivminigametick.
    _patient setVariable ["ACME_IV_Marks", _marks, true];
    _patient setVariable ["ACME_IV_MarkVer", (_patient getVariable ["ACME_IV_MarkVer", 0]) + 1, true];
    uiNamespace setVariable ["ACME_IV_MarkVerSeen", (_patient getVariable ["ACME_IV_MarkVer", 0])];
};
[] call ACME_fnc_ivMinigameRenderMarks;
