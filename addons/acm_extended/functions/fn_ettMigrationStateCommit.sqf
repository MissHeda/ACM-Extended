/* Phase 80: authoritative writer for durable ETT migration / obstruction state.
 * Operations:
 *   [patient,"placement",[depth, frame, mainstem]]
 *   [patient,"obstruction",[active, untilOr"__KEEP__"]]
 * Values omitted or "__KEEP__" retain current state. This preserves legacy paths that cleared the
 * obstruction boolean without rewriting the existing obstruction deadline.
 */
params ["_patient", "_op", ["_data", []]];
if (isNull _patient) exitWith {};
private _keep = "__KEEP__";
switch (toLower _op) do {
    case "placement": {
        private _depth = _data param [0, _keep];
        private _frame = _data param [1, _keep];
        private _mainstem = _data param [2, _keep];
        if !(_depth isEqualTo _keep) then {_patient setVariable ["ACME_ETT_Depth", _depth, true];};
        if !(_frame isEqualTo _keep) then {_patient setVariable ["ACME_ETT_Frame", _frame, true];};
        if !(_mainstem isEqualTo _keep) then {_patient setVariable ["ACME_ETT_Mainstem", _mainstem, true];};
    };
    case "obstruction": {
        private _active = _data param [0, _keep];
        private _until = _data param [1, _keep];
        if !(_active isEqualTo _keep) then {_patient setVariable ["ACME_ETT_Obstructing", _active, true];};
        if !(_until isEqualTo _keep) then {_patient setVariable ["ACME_ETT_ObstructUntil", _until, true];};
    };
};
