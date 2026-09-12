/* Send a deliberate physical band operation to the patient owner.
   Reopening or observing a limb must never publish a band operation. */
params [["_on", false, [true]]];
if !([] call ACME_fnc_ivUiValid) exitWith {};
if (uiNamespace getVariable ["ACME_IV_EJMode", false]) exitWith {};
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = toLower (uiNamespace getVariable ["ACME_IV_BodyPart", ""]);
private _index = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find _bp;
if (!(_index in [2,3,4,5]) || {isNull _patient}) exitWith {};
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
private _band = [_on,
    uiNamespace getVariable ["ACME_IV_Site", "middle"],
    uiNamespace getVariable ["ACME_IV_BandUV", []],
    uiNamespace getVariable ["ACME_IV_VeinUV", []],
    uiNamespace getVariable ["ACME_IV_Label", ""],
    uiNamespace getVariable ["ACME_IV_BandTex", ""]];
private _state = _patient getVariable [format ["ACME_IV_BandState_%1", _index], []];
private _display = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (!isNull _display) then {
    // This deadline is local UI time. It is never sent over the network.
    _display setVariable ["ACME_IV_BandPending", [_state param [0, 0], diag_tickTime + 5, _index, _on, _view, +_band]];
};
[_patient, "ivState", [_patient, "band", [_index, _on, _view, _band],
    [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
