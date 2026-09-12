#include "\x\ACM\addons\core\script_component.hpp"
/* Decide whether a medication event can create peripheral-IV exposure.
   The active ACM medication class owns administrationType. Labels and body part do not.
   ACM core/ACM_Medication.hpp gives PO, inhaled and BUC classes non-IV kinetics.
   medicationLocal appends the actual IV/IO flag. Older four-field events use the config route.
   No wound, dose, patient state or log is changed by this query. */
params [["_classname", "", [""]], ["_viaIV", objNull]];
private _config = configFile >> "ACM_Medication" >> "Medications" >> _classname;
if (!isClass _config) exitWith {false};
private _route = _config >> "administrationType";
if (!isNumber _route) exitWith {false};
if ((getNumber _route) != ACM_ROUTE_IV) exitWith {false};
// Only an omitted flag may use the legacy route fallback. Explicit false always blocks exposure.
if (_viaIV isEqualType objNull) exitWith {isNull _viaIV};
_viaIV isEqualTo true
