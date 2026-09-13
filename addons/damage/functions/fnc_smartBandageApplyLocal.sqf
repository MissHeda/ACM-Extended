#include "..\script_component.hpp"
/* Patient-owner application. One network event carries the whole bundle; native ACE bandageLocal remains the
   authority for wound reduction/reopening/trauma behavior for every individual dressing. */
params ["_patient", "_bodyPart", "_treatments"];
if (isNull _patient || {!local _patient}) exitWith {};
{
    private _open = _patient getVariable ["ace_medical_openWounds", createHashMap];
    if ((_open getOrDefault [toLowerANSI _bodyPart, []]) isEqualTo []) exitWith {};
    [_patient, _bodyPart, _x, 1] call ace_medical_treatment_fnc_bandageLocal;
} forEach _treatments;
