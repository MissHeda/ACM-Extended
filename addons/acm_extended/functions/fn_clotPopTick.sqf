// a server pass: pushing factor-poor non-blood fluid, meaning crystalloid, into a hemodynamically unstable patient
// pops fresh clots. that is dilutional coagulopathy plus rising pressure tearing soft clots loose, which is the
// tccc rationale for blood-first resuscitation.
// the instability is read as the actual blood volume, because crystalloid raises the saline and plasma volume
// rather than the blood volume, so it cannot game this gate: only a real blood transfusion makes the patient
// stable and stops the popping.
// each pass, an unstable patient with a crystalloid bag running has a chance, scaled by how much non-blood is on
// board and how deep the shock is, to reopen a bandaged wound.
if (!isServer) exitWith {};
if !(missionNamespace getVariable ["ACME_clotPop_enabled", true]) exitWith {};

private _bvThresh = missionNamespace getVariable ["ACME_clotPop_bvThreshold", 5.1];  // liters of real blood. normal is 6.
private _base     = missionNamespace getVariable ["ACME_clotPop_chance", 0.30];
private _frac     = missionNamespace getVariable ["ACME_clotPop_fraction", 0.5];
private _types    = missionNamespace getVariable ["ACME_clotPop_fluidTypes", ["Saline", "PlasmaLyte"]];

{
    private _u = _x;
    private _bv = _u getVariable ["ACM_circulation_Blood_Volume", 6];
    if (_bv < _bvThresh) then {  // hemodynamically unstable, meaning hypovolemic.
        // is a dilutional fluid actively running?
        private _bags = _u getVariable ["ACM_circulation_IV_Bags", createHashMap];
        private _infusing = false;
        {
            {
                _x params ["_t", "_vol"];
                if (_vol > 1 && {_t in _types}) exitWith { _infusing = true; };
            } forEach _y;
            if (_infusing) exitWith {};
        } forEach _bags;
        if (_infusing) then {
            private _load   = (_u getVariable ["ACM_circulation_Saline_Volume", 0]) + (_u getVariable ["ACM_circulation_Plasma_Volume", 0]);
            private _loadF  = linearConversion [0.1, 1.5, _load, 0.4, 1.6, true];  // more crystalloid on board gives more risk.
            private _shockF = linearConversion [_bvThresh, 3.5, _bv, 1, 2, true];  // deeper shock gives more risk.
            // the pressure factor. the header of this function has always given rising pressure tearing soft clots loose as half
            // its rationale, and the code only ever implemented the dilutional half. a fresh clot is a soft plug held on by
            // nothing much, and what strips it off is the pressure behind it. now that MAP drives bleeding it should drive
            // this too, or the two halves of the same idea disagree.
            private _mapF = 1;
            if (missionNamespace getVariable ["ACME_sys_permHypo", true]) then {
                private _pm = [_u] call ACME_fnc_tbiGetMAP;
                if (!isNil "_pm" && {_pm isEqualType 0} && {_pm > 0}) then {
                    _mapF = linearConversion [
                        (missionNamespace getVariable ["ACME_permHypo_refMAP", 70]),
                        (missionNamespace getVariable ["ACME_clotPop_mapCeiling", 100]),
                        _pm, 1, (missionNamespace getVariable ["ACME_clotPop_mapMaxFactor", 1.8]), true
                    ];
                };
            };
            // capped. these four factors multiply and nothing ever bounded the result: 0.30 times 1.6 times 2.0 times 1.8 is
            // 1.73, which is not a probability at all. past 1.0 the roll stops being a roll and a wound reopens every pass,
            // guaranteed, every 8 seconds, half the bandaged wounds at a time. that is the bandages-popping-off report, and it
            // is why it looked like a switch rather than a risk.
            // the ceiling is 0.45 a pass: at the very worst, roughly one reopen every 18 s, which is a casualty losing ground
            // fast without the game taking the decision away from the medic.
            private _pop = (_base * _loadF * _shockF * _mapF) min (missionNamespace getVariable ["ACME_clotPop_maxChance", 0.45]);
            if (random 1 < _pop) then {
                ["ACME_popClots", [_u, _frac], _u] call CBA_fnc_targetEvent;
            };
        };
    };
} forEach (allUnits select { alive _x && {_x getVariable ["ACM_circulation_IV_Bags_Active", false]} });
