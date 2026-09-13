#include "..\script_component.hpp"
/* ACM Extended treatment bridge.
 * ACME owns only provider preflight, requested intervention-specific gestures, and the ventilator connector.
 * Native ACM/ACE remains authoritative for treatment timing, inventory, callbacks, cancellation and patient state.
 */
params ["_medic", "_patient", "_bodyPart", "_classname"];

if !([_medic, _classname] call ACME_fnc_procedureActionAllowed) exitWith {false};

if (_classname != "ACME_ConnectETVent") exitWith {
    // Preserve ACM/ACE cursor-menu deferral before ACME starts its one-shot stance/weapon preflight.
    if (uiNamespace getVariable ["ace_interact_menu_cursorMenuOpened", false]) exitWith {
        [ace_medical_treatment_fnc_treatment, _this] call CBA_fnc_execNextFrame;
        true
    };

    // Continuous ACM actions own their complete animation/cancellation lifecycle.
    private _nativeContinuousClass = toLowerANSI _classname;
    if (_nativeContinuousClass in ["cpr", "usebvm", "usebvm_oxygen", "usebvm_vehicleoxygen", "usebvm_portableoxygen"]) exitWith {
        _this call ACM_core_fnc_treatmentNative
    };

    // Resolve ACME's provider-theatre policy BEFORE native treatment starts. When one of these modes is selected,
    // fn_treatmentNative is told not to enqueue ACM/ACE's generic medic animation. Previously the native bandage
    // motion was already in the animation queue by the time ACME started the requested chest/head/NCD gesture, so
    // it won later and made the specific animation appear to never play.
    private _cfg = configFile >> "ace_medical_treatment_actions" >> _classname;
    private _category = toLowerANSI getText (_cfg >> "category");
    private _part = toLowerANSI _bodyPart;
    private _classKey = toLowerANSI _classname;
    private _torso = _part in ["body", "torso", "chest", "abdomen"];
    private _mode = "";
    private _exactAnim = "";
    private _gestureWindow = 2.4;

    if ((_classKey find "performncd") >= 0 || {(_classKey find "narspear") >= 0}) then {
        _mode = "ncdSeat";
        _gestureWindow = 5.0;
    } else {
        if ((_classKey find "checkbreathing") >= 0) then {
            _exactAnim = "AinvPknlMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon_medic";
        } else {
            if (_torso && {(_classKey find "pressurebandage") >= 0}) then {
                _exactAnim = "AinvPknlMstpSnonWnonDnon_medic3";
            } else {
                if (_torso && {(_classKey find "emergencytraumadressing") >= 0}) then {
                    _exactAnim = "AinvPknlMstpSnonWnonDnon_medic4";
                } else {
                    if (_category == "bandage" && {_torso}) then {
                        _mode = "torsoBandage";
                    } else {
                        if (_category == "bandage" && {_part == "head"}) then {
                            private _relative = _patient worldToModel (getPosWorld _medic);
                            _mode = ["headBandageLeft", "headBandageRight"] select ((_relative param [0, 0]) > 0);
                        };
                    };
                };
            };
        };
    };
    private _ownsProviderAnim = (_mode != "") || {_exactAnim != ""};

    // One empty-hands request and one transition to crouch before native treatment starts.
    private _bypass = _medic getVariable ["ACME_treatmentPreflightBypass", []];
    private _isBypass = (_bypass isEqualType []) && {count _bypass >= 3}
        && {(_bypass select 0) isEqualTo _patient}
        && {(_bypass select 1) == _bodyPart}
        && {(_bypass select 2) == _classname};
    private _headOwned = _classname in ["ACME_ElevateHead", "ACME_LowerHead"];

    // Fast path: if the provider is already empty-handed and crouched, start the treatment immediately.
    // The old wrapper always bounced through waitUntilAndExecute even when no transition was required, which
    // added a perceptible one-frame click delay to every medical-menu action.
    private _animNow = if (!isNull _medic) then {toLowerANSI animationState _medic} else {""};
    private _visuallyEmptyNow = !isNull _medic && {
        (currentWeapon _medic == "") || {((_animNow find "wnon") >= 0) && {((_animNow find "snon") >= 0)}}
    };
    private _preflightReady = _visuallyEmptyNow && {stance _medic == "CROUCH"};

    if (!_isBypass && {!_headOwned} && {!_preflightReady} && {local _medic} && {!isNull _medic} && {alive _medic} && {isNull objectParent _medic}) exitWith {
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

        private _args = +_this;
        private _token = format ["%1:%2:%3", clientOwner, netId _medic, diag_tickTime];
        _medic setVariable ["ACME_treatmentPreflightToken", _token, false];

        [{
            params ["_m", "_args", "_tok"];
            if (isNull _m || {!alive _m} || {!local _m}
                || {(_m getVariable ["ACME_treatmentPreflightToken", ""]) != _tok}) exitWith {true};
            private _anim = toLowerANSI animationState _m;
            private _visuallyEmpty = (currentWeapon _m == "") || {
                ((_anim find "wnon") >= 0) && {((_anim find "snon") >= 0)}
            };
            _visuallyEmpty && {stance _m == "CROUCH"}
        }, {
            params ["_m", "_args", "_tok"];
            if (isNull _m || {!alive _m} || {!local _m}
                || {(_m getVariable ["ACME_treatmentPreflightToken", ""]) != _tok}) exitWith {
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
        }, [_medic, _args, _token], 3.0, {
            params ["_m", "_args", "_tok"];
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

    // Head positioning is head-selection only. Pass the selected body part through unchanged.
    private _nativeArgs = +_this;

    if (_ownsProviderAnim && {local _medic}) then {
        _medic setVariable ["ACME_suppressNativeTreatmentAnim", true, false];
    };
    private _started = _nativeArgs call ACM_core_fnc_treatmentNative;
    if (local _medic) then {
        _medic setVariable ["ACME_suppressNativeTreatmentAnim", false, false];
    };

    if (_started && {local _medic} && {!isNull _medic} && {isNull objectParent _medic}) then {
        // Every finite ACME-owned provider animation exits to empty-handed crouch.
        private _end = _medic getVariable ["ace_medical_treatment_endInAnim", ""];
        if (_end != "") then {
            _medic setVariable ["ace_medical_treatment_endInAnim", "AmovPknlMstpSnonWnonDnon"];
        };

        if (_mode != "") then {
            [{
                params ["_m", "_mode", "_window"];
                if (!isNull _m && {alive _m} && {local _m}) then {
                    [_m, _mode, _window] call ACME_fnc_treatmentGesture;
                };
            }, [_medic, _mode, _gestureWindow]] call CBA_fnc_execNextFrame;
        } else {
            if (_exactAnim != "") then {
                [{
                    params ["_m", "_anim"];
                    if (!isNull _m && {alive _m} && {local _m}) then {
                        [_m, _anim, 1] call ACME_fnc_doAnim;
                    };
                }, [_medic, _exactAnim]] call CBA_fnc_execNextFrame;
            } else {
                if (_category != "bandage" && {_medic getVariable ["ACME_DP_Active", false]} && {random 1 < 0.30}) then {
                    [{
                        params ["_m"];
                        if (!isNull _m && {alive _m} && {local _m}) then {
                            [_m, "directPressureAction", 1.6] call ACME_fnc_treatmentGesture;
                        };
                    }, [_medic]] call CBA_fnc_execNextFrame;
                };
            };
        };
    };
    _started
};

// Ventilator connector: inventory/state is committed only after its own acknowledgement path accepts the action.
if (!local _medic || {isNull _medic} || {isNull _patient}) exitWith {false};
if (uiNamespace getVariable ["ace_interact_menu_cursorMenuOpened", false]) exitWith {
    [ace_medical_treatment_fnc_treatment, _this] call CBA_fnc_execNextFrame;
    true
};
if !(_this call ace_medical_treatment_fnc_canTreat) exitWith {false};
if !([_medic, _patient, ["isNotInside", "isNotSwimming", "isNotInZeus"]] call ace_common_fnc_canInteractWith) exitWith {false};
if !([_medic, _patient] call ACME_fnc_ventRecoveryNear) exitWith {false};
[_medic, _patient] call ACME_fnc_ventConnectPatient;
true
