#include "..\script_component.hpp"
/* B11: the ventilator connector has its own acknowledged inventory transaction.
   All other actions retain the supplied ACM treatment implementation. */
params ["_medic", "_patient", "_bodyPart", "_classname"];
if !([_medic, _classname] call ACME_fnc_procedureActionAllowed) exitWith {false};
if (_classname != "ACME_ConnectETVent") exitWith {
    // Preserve ACM/ACE's cursor-menu deferral BEFORE ACME starts its one-shot stance/weapon preflight. Otherwise a
    // native next-frame deferral could re-enter after the bypass token was cleared and perform the preflight twice.
    if (uiNamespace getVariable ["ace_interact_menu_cursorMenuOpened", false]) exitWith {
        [ace_medical_treatment_fnc_treatment, _this] call CBA_fnc_execNextFrame;
        true
    };
    // B90 critical continuous-action guard. CPR and every BVM variant belong to ACM. Do not run ACME's
    // provider stance/weapon preflight, end-animation rewrite, or finite treatment theatre around them. Native ACM
    // owns their key handlers, continuous-action lifecycle, movement state, animation loop and cancellation.
    private _nativeContinuousClass = toLowerANSI _classname;
    if (_nativeContinuousClass in ["cpr", "usebvm", "usebvm_oxygen", "usebvm_vehicleoxygen", "usebvm_portableoxygen"]) exitWith {
        _this call ACM_core_fnc_treatmentNative
    };
    // B72 provider preflight. Native ACM snapshots currentWeapon and stance synchronously and can therefore see a
    // pistol/launcher that ACME only asked to holster earlier in the same frame. That creates the wrong weapon-
    // specific medic animation and later redraws the weapon. Do one empty-hands request, enter crouch once, then
    // start native treatment only after those states have actually settled. No retry holster and no weapon restore.
    private _bypass = _medic getVariable ["ACME_treatmentPreflightBypass", []];
    private _isBypass = (_bypass isEqualType []) && {count _bypass >= 3}
        && {(_bypass select 0) isEqualTo _patient} && {(_bypass select 1) == _bodyPart} && {(_bypass select 2) == _classname};
    private _headOwned = _classname in ["ACME_ElevateHead", "ACME_LowerHead"];
    if (!_isBypass && {!_headOwned} && {local _medic} && {!isNull _medic} && {alive _medic} && {isNull objectParent _medic}) exitWith {
        if (_medic getVariable ["ACME_treatmentPreflightActive", false]) exitWith {false};
        _medic setVariable ["ACME_treatmentPreflightActive", true, false];
        [_medic] call ACME_fnc_medicAnimationPrep;
        _medic setUnitPos "MIDDLE";

        private _transition = switch (stance _medic) do {
            case "STAND": {"AmovPercMstpSnonWnonDnon_AmovPknlMstpSnonWnonDnon"};
            case "PRONE": {"AmovPpneMstpSnonWnonDnon_AmovPknlMstpSnonWnonDnon"};
            default {""};
        };
        if (_transition != "") then {[_medic, _transition, 1] call ACME_fnc_doAnim;};

        private _argsB72 = +_this;
        private _tokenB72 = format ["%1:%2:%3", clientOwner, netId _medic, diag_tickTime];
        _medic setVariable ["ACME_treatmentPreflightToken", _tokenB72, false];
        [{
            params ["_m","_args","_tok"];
            isNull _m || {!alive _m} || {!local _m}
                || {(_m getVariable ["ACME_treatmentPreflightToken", ""]) != _tok}
                || {(currentWeapon _m == "") && {stance _m == "CROUCH"}}
        }, {
            params ["_m","_args","_tok"];
            if (isNull _m || {!alive _m} || {!local _m}
                || {(_m getVariable ["ACME_treatmentPreflightToken", ""]) != _tok}) exitWith {
                // A destroyed/non-local provider cannot continue. Never clear a newer token owned by a later action.
                if (!isNull _m && {local _m} && {(_m getVariable ["ACME_treatmentPreflightToken", ""]) == _tok}) then {
                    _m setVariable ["ACME_treatmentPreflightActive", false, false];
                    _m setVariable ["ACME_treatmentPreflightToken", "", false];
                    _m setUnitPos "AUTO";
                };
            };
            _m setVariable ["ACME_treatmentPreflightActive", false, false];
            _m setVariable ["ACME_treatmentPreflightBypass", [_args select 1, _args select 2, _args select 3], false];
            _args call ace_medical_treatment_fnc_treatment;
            _m setVariable ["ACME_treatmentPreflightBypass", [], false];
            _m setVariable ["ACME_treatmentPreflightToken", "", false];
        }, [_medic,_argsB72,_tokenB72], 3.0, {
            // Never fall through into native ACM while a pistol/rifle/launcher is still selected or the provider is
            // still standing. That exact timeout fall-through was capable of recreating ACM's weapon-specific medic
            // state and automatic redraw. One stow request was already made above; on a pathological move-graph/mod
            // conflict, release the stance lock and let the provider retry instead of starting the wrong animation.
            params ["_m","_args","_tok"];
            if (isNull _m || {!local _m} || {(_m getVariable ["ACME_treatmentPreflightToken", ""]) != _tok}) exitWith {};
            _m setVariable ["ACME_treatmentPreflightActive", false, false];
            _m setVariable ["ACME_treatmentPreflightBypass", [], false];
            _m setVariable ["ACME_treatmentPreflightToken", "", false];
            _m setUnitPos "AUTO";
        }] call CBA_fnc_waitUntilAndExecute;
        true
    };
    if (_isBypass) then {
        _medic setVariable ["ACME_treatmentPreflightActive", false, false];
    };
    // B71: ACM treats numeric ACM_rollToBack = 0 as "roll when Body was selected". Head elevation/lowering
    // deliberately allow both Head and Body menu selections, so normalize only these two actions to Head for the
    // native treatment engine. Their ACME callbacks do not depend on body-part anatomy and own the real prone-only
    // roll themselves. This prevents an already-supine casualty from taking any native front/back detour.
    private _nativeArgs = +_this;
    if (_classname in ["ACME_ElevateHead", "ACME_LowerHead"] && {toLowerANSI _bodyPart == "body"}) then {
        _nativeArgs set [2, "Head"];
    };
    private _started = _nativeArgs call ACM_core_fnc_treatmentNative;
    if (_started && {local _medic} && {!isNull _medic} && {isNull objectParent _medic}) then {
        private _end = _medic getVariable ["ace_medical_treatment_endInAnim", ""];
        if (_end != "") then {_medic setVariable ["ace_medical_treatment_endInAnim", "AmovPknlMstpSnonWnonDnon"]};

        // B52 explicit animation policy. These gestures replace generic provider theatre only for the anatomical
        // cases requested by the project; all unrelated ACM actions retain ACM's own animation.
        private _cfgB52 = configFile >> "ace_medical_treatment_actions" >> _classname;
        private _catB52 = toLowerANSI getText (_cfgB52 >> "category");
        private _partB52 = toLowerANSI _bodyPart;
        if (_catB52 == "bandage") then {
            private _modeB52 = "";
            if (_partB52 in ["body","torso","chest","abdomen"]) then {_modeB52 = "torsoBandage";};
            if (_partB52 == "head") then {
                private _relB52 = _patient worldToModel (getPosWorld _medic);
                // model-space x: negative is the patient's left, positive the patient's right.
                _modeB52 = ["headBandageLeft","headBandageRight"] select ((_relB52 param [0,0]) > 0);
            };
            if (_modeB52 != "") then {
                [{params ["_m","_mode"]; [_m,_mode,2.4] call ACME_fnc_treatmentGesture;},[_medic,_modeB52]] call CBA_fnc_execNextFrame;
            };
        } else {
            if (_medic getVariable ["ACME_DP_Active",false] && {random 1 < 0.30}) then {
                [{params ["_m"]; [_m,"directPressureAction",1.6] call ACME_fnc_treatmentGesture;},[_medic]] call CBA_fnc_execNextFrame;
            };
        };
    };
    _started
};
if (!local _medic || {isNull _medic} || {isNull _patient}) exitWith {false};
if (uiNamespace getVariable ["ace_interact_menu_cursorMenuOpened", false]) exitWith {
    [ace_medical_treatment_fnc_treatment, _this] call CBA_fnc_execNextFrame;
    true
};
if !(_this call ace_medical_treatment_fnc_canTreat) exitWith {false};
if !([_medic, _patient, ["isNotInside", "isNotSwimming", "isNotInZeus"]] call ace_common_fnc_canInteractWith) exitWith {false};
if !([_medic, _patient] call ACME_fnc_ventRecoveryNear) exitWith {false};
// Do not close the medical menu, consume an item, or publish provisional patient state.
// fn_ventInventoryLocal and fn_ventCustodyAck own those changes after acceptance.
[_medic, _patient] call ACME_fnc_ventConnectPatient;
true
