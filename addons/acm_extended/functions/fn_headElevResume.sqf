// Restore the elevated animation after a maneuver, provided elevation was not canceled.
params ["_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevResume", [_patient]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};
if !(_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {};

private _suspendVest = +(_patient getVariable ["ACME_headElev_suspendVestLoadout", []]);
if ((count _suspendVest) == 2) then {
    private _vestClass = _suspendVest param [0, "", [""]];
    if (_vestClass != "") then {
        // The flat-treatment phase intentionally put the carrier back on the chest. Take that exact carrier back
        // into elevation custody, then rebuild the non-simulated bolster before the lift animation starts.
        if ((vest _patient) == _vestClass) then {
            private _items = vestItems _patient;
            removeVest _patient;
            if ((vest _patient) == "") then {
                _patient setVariable ["ACME_headElev_vestLoadout", +_suspendVest, true];
                _patient setVariable ["ACME_headElev_vestRemoved", true, true];
                _patient setVariable ["ACME_headElev_propVest", _vestClass, true];
                _patient setVariable ["ACME_headElev_propVestItems", _items, true];

                private _model = getText (configFile >> "CfgWeapons" >> _vestClass >> "model");
                private _prop = objNull;
                if (_model != "") then {_prop = createSimpleObject [_model, [0,0,0], false];};
                if (isNull _prop) then {
                    _prop = createVehicle ["GroundWeaponHolder", getPosATL _patient, [], 0, "CAN_COLLIDE"];
                    _prop addItemCargoGlobal [_vestClass, 1];
                };
                _patient setVariable ["ACME_headElev_propObj", _prop, true];
            };
        };
    };
};
_patient setVariable ["ACME_headElev_suspendVestLoadout", [], false];
_patient setVariable ["ACME_headElev_suspendReadyAt", -1, false];
_patient setVariable ["ACME_headElev_Suspended", false, true];
_patient setVariable ["ACME_headElev_basePosASL", getPosASL _patient, true];
_patient setVariable ["ACME_headElev_baseDir", getDir _patient, true];
[_patient] call ACME_fnc_headElevPropApply;
[_patient] call ACME_fnc_headElevApplyTilt;
