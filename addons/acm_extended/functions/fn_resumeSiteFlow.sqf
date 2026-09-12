// restart the per-site transfusion flow of ACM if it is stopped. ACM gates all delivery on a per-bodypart,
// per-site 0 or 1 flow multiplier, ACM_circulation_FluidBagsFlow_IV and _io, written by the stop and start
// toggle. once the flow of a line hit 0, because the site went dead or the medic stopped it to work the line,
// bags hung by the direct paths of the mod, meaning a used-bag re-hang, y refills and prepared-set hangs, would
// sit without flowing.
// call this after any such hang, so adding a bag back to a line always starts it flowing again. a running site,
// with a flow above 0, including any partial value, is left untouched.
// call it as [_patient, _bodyPart, _iv, _accessSite] call ACME_fnc_resumeSiteFlow.
params ["_patient", "_bodyPart", ["_iv", true], ["_accessSite", -1]];
if (isNull _patient || {_bodyPart isEqualTo ""}) exitWith {};

// re-arm the patient-level master transfusion switch of ACM. the entire drain loop is wrapped in IV_Bags_Active.
// ACM's own hang path, ivbaglocal, sets it, and the direct-write hangs of the mod do not, and it goes false
// whenever the bag map of the patient empties, such as after discarding y tubing. without this, a bag re-hung by
// the mod after a discard sits on the line and never drains whatever the per-site flow says.
[_patient, [["ivBagsActive", true]], true] call ACM_circulation_fnc_setRuntimeState;

private _pi = ACME_infusion_bodyParts find toLowerANSI _bodyPart;
if (_pi < 0) exitWith {};

if (_iv) then {
    if (_accessSite < 0) exitWith {};
    private _fa = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IV", [[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1],[1,1,1]]]);
    if (_pi >= count _fa) exitWith {};
    private _pf = +(_fa select _pi);
    if (_accessSite >= count _pf) exitWith {};
    if ((_pf select _accessSite) == 0) then {
        _pf set [_accessSite, 1];
        _fa set [_pi, _pf];
        [_patient, [["fluidBagsFlowIV", _fa]], true] call ACM_circulation_fnc_setRuntimeState;
    };
} else {
    private _fa = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IO", [1,1,1,1,1,1]]);
    if (_pi >= count _fa) exitWith {};
    if ((_fa select _pi) == 0) then {
        _fa set [_pi, 1];
        [_patient, [["fluidBagsFlowIO", _fa]], true] call ACM_circulation_fnc_setRuntimeState;
    };
};
