/* B14: only dose-bound sugammadex availability is customized; opioids remain vanilla. */
params ["_patient", "_record"];
private _class = _record param [0, ""];
private _type = _record param [13, ""];
if (_class in ["Rocuronium", "Rocuronium_IV"]) exitWith {
    private _uid = _record param [15, ""];
    private _bound = (_patient getVariable ["ACME_sug_bindings", []]) select {(_x param [0, ""]) == _uid && {_uid != ""}};
    private _amount = if (_bound isEqualTo []) then {0} else {(_bound select 0) param [1, 0]};
    1 - ((_amount / ((_record param [12, 0]) max 0.000001)) max 0 min 1)
};
1
