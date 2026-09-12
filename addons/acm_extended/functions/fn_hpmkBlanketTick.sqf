// manage the HPMK blanket visual without ever attaching a networked object to a wrapped patient.
//
// B28 invariant:
//   WRAPPED PATIENT = client-local simple-object visual that mirrors the casualty without attachTo.
//   DROPPED HPMK    = one server-owned, geometry-free Land_HelipadEmpty_F anchor + client-local visual.
//
// No server-owned object is attached to a casualty while they are wrapped. This matters because a disabled-sim
// network object in an attachTo chain can still fight ACE drag/carry/reposition ownership during ragdoll/pose
// transitions even when the child has no collision geometry. The visible wrapped blanket is cosmetic only and a
// local createSimpleObject has no parent/child transform relationship with the casualty physics.
if (!isServer) exitWith {};

private _class = missionNamespace getVariable ["ACME_hpmk_blanketClass", ""];

private _fnc_killLegacy = {
    params ["_unit"];
    private _b = _unit getVariable ["ACME_hpmk_blanket", objNull];
    if (!isNull _b) then { deleteVehicle _b; };
    [_unit, "ACME_hpmk_blanket", objNull] call ACME_fnc_setVarNet;
};

// If the feature is disabled, tear down any legacy wrapped anchor that may have survived from an older state.
if !(missionNamespace getVariable ["ACME_sys_hpmk", true]) exitWith {
    { if (!isNull _x) then { [_x] call _fnc_killLegacy; }; } forEach allUnits;
};

{
    private _p = _x;
    private _wrapped = (_p getVariable ["ACME_hpmk_on", false]) && {alive _p};
    private _legacy = _p getVariable ["ACME_hpmk_blanket", objNull];

    // B28: an attached/networked blanket anchor is legacy state and is never retained on a wrapped casualty.
    if (!isNull _legacy) then { [_p] call _fnc_killLegacy; };

    if (!_wrapped) then { continue; };

    // A wrapped patient who gets up under their own power sheds the HPMK. Only at that moment do we create the
    // networked anchor, because the dropped blanket needs an ACE interaction target that every client can see.
    // Drag/carry never qualifies as "got up" because attached/dragged/carried patients fail this gate.
    private _externallyHeld = !(isNull attachedTo _p)
        || {_p getVariable ["ace_dragging_isDragged", false]}
        || {_p getVariable ["ace_dragging_isCarried", false]}
        || {_p call ace_common_fnc_isBeingDragged}
        || {_p call ace_common_fnc_isBeingCarried};

    if ((vehicle _p == _p) && {!_externallyHeld} && {(stance _p) in ["STAND", "CROUCH"]}) then {
        if (_class != "") then {
            private _drop = [_class, getPosATL _p] call ACME_fnc_hpmkSpawnBlanket;
            if (!isNull _drop) then {
                _drop setPosATL (getPosATL _p);
                _drop setDir (getDir _p);
                [_drop, "ACME_hpmk_dropped", true] call ACME_fnc_setVarNet;
            };
        };
        [_p, "", true, true] call ACME_fnc_hpmkStateCommit;
        [_p, "ACM_HPMK_Remove"] remoteExec ["ACME_fnc_remoteSay3D", 0];
        if (!isNil "ace_medical_treatment_fnc_addToLog") then {
            [_p, "activity", "HPMK slipped off (patient got up)", []] call ace_medical_treatment_fnc_addToLog;
        };
    };
} forEach allUnits;
