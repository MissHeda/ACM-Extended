/*
 * Phase 24 subsystem ownership: HPMK blanket reconciliation, pickup interaction and client visual runtime.
 *
 * Extracted intact from ACME_fnc_postInit and invoked at the original point so startup
 * sequencing and CBA registration order are preserved.
 */

[{call ACME_fnc_hpmkBlanketTick}, 0.5, []] call CBA_fnc_addPerFrameHandler;

// the "Pick Up HPMK" ACE object interaction on a dropped blanket, shed when a wrapped patient got up. it
// registers per client, through addactiontoclass with a hasinterface guard inside createaction, and gates on
// ACME_hpmk_dropped. it therefore shows on our dropped blankets only, not on map clutter of the same class.
// execnextframe runs it after ACE's interact_menu is initialized. if ACME_hpmk_blanketClass is retuned, move
// this to the new class.
if (hasInterface) then {
    [{
        if (isNil "ace_interact_menu_fnc_createAction") exitWith {};
        private _act = [
            "ACME_PickUpHPMK",
            "Pick Up HPMK",
            "\acm_extended\ui\items\HPMK_ca.paa",
            { [_target, _player] call ACME_fnc_hpmkPickUp; },
            { _target getVariable ["ACME_hpmk_dropped", false] }
        ] call ace_interact_menu_fnc_createAction;
        // the interaction now lives on the collision-free anchor, Land_HelipadEmpty_F, and not on the blanket prop,
        // because the blanket prop no longer exists as a networked object. it is a client-side simple object with no
        // collision. it gates on ACME_hpmk_dropped, so an ordinary helipad never shows this.
        ["Land_HelipadEmpty_F", 0, [], _act] call ace_interact_menu_fnc_addActionToClass;
    }] call CBA_fnc_execNextFrame;
};


// HPMK blanket visuals, client-side.
// B28 deliberately separates wrapped and dropped presentation:
//   - wrapped: a local simple object mirrors the casualty transform without attachTo; there is no child object.
//   - dropped: the existing geometry-free server anchor remains, because it is the shared ACE interaction target.
// This removes every attachTo relationship that could fight ACE drag/carry/reposition and make a casualty float.
if (hasInterface) then {
    ACME_hpmk_visuals = createHashMap;         // dropped anchor netId -> local simple object
    ACME_hpmk_wrappedVisuals = createHashMap;  // patient netId -> local simple object
    [{
        private _class = missionNamespace getVariable ["ACME_hpmk_blanketClass", ""];
        private _feature = missionNamespace getVariable ["ACME_sys_hpmk", true];

        // Dropped world blankets: reconcile from network anchors.
        private _seenDrop = [];
        if (_feature && {_class != ""}) then {
            {
                private _anchor = _x;
                private _id = netId _anchor;
                _seenDrop pushBack _id;
                if (isNil { ACME_hpmk_visuals get _id }) then {
                    private _model = _anchor getVariable ["ACME_hpmk_visualClass", _class];
                    if (_model != "") then {
                        private _vis = createSimpleObject [_model, [0,0,0], true];
                        _vis setPosWorld (getPosWorldVisual _anchor);
                        _vis setVectorDirAndUp [vectorDirVisual _anchor, vectorUpVisual _anchor];
                        ACME_hpmk_visuals set [_id, _vis];
                    };
                };
            } forEach ((ACE_player nearObjects ["Land_HelipadEmpty_F", 120]) select {_x getVariable ["ACME_hpmk_isBlanket", false]});
        };
        {
            private _id = _x;
            if !(_id in _seenDrop) then {
                private _vis = ACME_hpmk_visuals get _id;
                if (!isNil "_vis" && {!isNull _vis}) then { deleteVehicle _vis; };
                ACME_hpmk_visuals deleteAt _id;
            };
        } forEach (keys ACME_hpmk_visuals);

        // Wrapped casualties: local-only presentation. A simple object is a child visual only; it has no physics,
        // no damage, no collision and no network ownership, so ACE can attach/move/ragdoll the casualty freely.
        private _seenWrapped = [];
        if (_feature && {_class != ""}) then {
            {
                private _patient = _x;
                if ((_patient getVariable ["ACME_hpmk_on", false]) && {alive _patient} && {vehicle _patient == _patient}) then {
                    private _id = netId _patient;
                    _seenWrapped pushBack _id;
                    if (isNil { ACME_hpmk_wrappedVisuals get _id }) then {
                        private _vis = createSimpleObject [_class, [0,0,0], true];
                        _vis setPosWorld (getPosWorldVisual _patient);
                        _vis setVectorDirAndUp [vectorDirVisual _patient, vectorUpVisual _patient];
                        ACME_hpmk_wrappedVisuals set [_id, [_vis, _patient]];
                    };
                };
            } forEach (allUnits select {!isNull _x && {_x distance ACE_player <= 120}});
        };
        {
            private _id = _x;
            if !(_id in _seenWrapped) then {
                private _entry = ACME_hpmk_wrappedVisuals get _id;
                if (!isNil "_entry") then {
                    private _vis = _entry param [0, objNull];
                    if (!isNull _vis) then { deleteVehicle _vis; };
                };
                ACME_hpmk_wrappedVisuals deleteAt _id;
            };
        } forEach (keys ACME_hpmk_wrappedVisuals);
    }, 1, []] call CBA_fnc_addPerFrameHandler;

    // Presentation follower only. The blanket is never an attached child of the casualty, eliminating the last
    // transform/physics relationship capable of fighting ACE drag, carry, recovery-position or patient placement.
    // We mirror the visual transform locally instead; no simulation, collision or network ownership is involved.
    [{
        {
            private _entry = ACME_hpmk_wrappedVisuals get _x;
            if (!isNil "_entry") then {
                _entry params [["_vis", objNull], ["_patient", objNull]];
                if (!isNull _vis && {!isNull _patient}) then {
                    _vis setPosWorld (getPosWorldVisual _patient);
                    _vis setVectorDirAndUp [vectorDirVisual _patient, vectorUpVisual _patient];
                };
            };
        } forEach (keys ACME_hpmk_wrappedVisuals);
    }, 0.05, []] call CBA_fnc_addPerFrameHandler;
};
