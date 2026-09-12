/* Accept an optional patient. Empty/PFH calls scan locally owned active patients. */
private _only = objNull;
if (_this isEqualType objNull) then {
    _only = _this;
} else {
    if (_this isEqualType [] && {count _this > 0}) then {
        private _candidate = _this select 0;
        if (_candidate isEqualType objNull) then {_only = _candidate;};
    };
};

// A menu can be opened by a medic who does not own the patient. Route the one-patient sync to the
// patient's owner so the registered medication state and the IV bag state have one writer.
if (!isNull _only && {!local _only}) exitWith {
    ["ACME_syncPremixedBagsLocal", [_only], _only] call CBA_fnc_targetEvent;
};

private _patients = if (isNull _only) then {
    (missionNamespace getVariable ["ACME_clinical_ownedUnits", []]) select {
        !isNull _x && {local _x} && {_x getVariable ["ACM_circulation_IV_Bags_Active", false]}
    }
} else {
    [_only]
};
{
    private _p = _x;
    if (isNull _p || {!local _p} || {!alive _p}) then {continue;};
    private _map = _p getVariable ["ACM_circulation_IV_Bags", createHashMap];
    {
        private _part = _x;
        {
            private _index = _forEachIndex; private _bag = _x;
            _bag params ["_type", "_remaining", "_at", "_site", "_iv", ["_bt", -1], ["_orig", 0], ["_fresh", -1]];
            if (_remaining <= 0) then {continue;};
            private _content = ACME_infusion_premixedByType getOrDefault [toLowerANSI _type, []];
            if (_content isEqualTo []) then {continue;};
            private _id = [_p, _part, _index] call ACME_fnc_bagIdentity;
            if (((_p getVariable ["ACME_infusion_BagMedications", []]) findIf {(_x param [23, ""]) == _id}) >= 0) then {continue;};
            _content params ["_med", "_dose"];
            // A partly used premixed bag contains only its proportional remaining medication.
            _dose = _dose * ((_remaining / (_orig max 0.001)) min 1);
            private _ctx = [_p, _part, _index, _type, _at, _site, _iv, _bt, _orig, _fresh, _remaining, _id];
            // A newly attached premix never delivers before the medic sets its clamp.
            [_ctx, _med, _dose, -1, -1, 0, 0] call ACME_fnc_registerBagMedication;
        } forEach _y;
    } forEach _map;
} forEach _patients;
