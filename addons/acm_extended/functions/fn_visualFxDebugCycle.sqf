params ["_medic","_patient",["_kind","hypoxia"]];
if (isNull _patient) exitWith {};
_kind = toLowerANSI _kind;
private _key = format ["ACME_visualFxDebug_%1",_kind];
private _next = ((_patient getVariable [_key,0]) + 1) mod 4;
_patient setVariable [_key,_next,true];
// Force the local mixer to reapply the wet profile on every ketamine severity transition.
// The handle itself remains alive so Mild -> Moderate -> Severe does not lose wave phase/persistence.
if (_kind isEqualTo "ketamine" && {_patient isEqualTo player}) then {
    uiNamespace setVariable ["ACME_VFX_WetForceRefresh",true];
    if (_next > 0) then {uiNamespace setVariable ["ACME_VFX_WetActive",true];};
};
private _label = switch (_kind) do {case "hypoxia":{"Hypoxia"}; case "hypotension":{"Hypotension / shock"}; case "hypercapnia":{"Hypercapnia"}; case "ketamine":{"Ketamine / dissociation"}; case "syncope":{"Near-syncope"}; default {_kind};};
private _sev = ["OFF","MILD","MODERATE","SEVERE"] select _next;
if (!isNull _medic) then {[format ["Visual FX %1: %2",_label,_sev],1.5,_medic] call ace_common_fnc_displayTextStructured;};
