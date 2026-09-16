params ["_medic","_patient",["_kind","hypoxia"]];
if (isNull _patient) exitWith {};
_kind = toLowerANSI _kind;
private _key = format ["ACME_visualFxDebug_%1",_kind];
private _next = ((_patient getVariable [_key,0]) + 1) mod 4;
_patient setVariable [_key,_next,true];
private _label = switch (_kind) do {case "hypoxia":{"Hypoxia"}; case "hypotension":{"Hypotension / shock"}; case "hypercapnia":{"Hypercapnia"}; case "ketamine":{"Ketamine / dissociation"}; case "syncope":{"Near-syncope"}; default {_kind};};
private _sev = ["OFF","MILD","MODERATE","SEVERE"] select _next;
if (!isNull _medic) then {[format ["Visual FX %1: %2",_label,_sev],1.5,_medic] call ace_common_fnc_displayTextStructured;};
