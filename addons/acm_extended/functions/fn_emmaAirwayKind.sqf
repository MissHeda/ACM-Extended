/* Return the airway actually fitted to this patient. ETT wins in inconsistent dual state. */
params [["_patient", objNull, [objNull]]];
if (isNull _patient) exitWith {""};
if (_patient getVariable ["ACME_ETT_Inserted", false]) exitWith {"ett"};
if ((_patient getVariable ["ACM_airway_AirwayItem_Oral", ""]) == "SGA") exitWith {"igel"};
""
