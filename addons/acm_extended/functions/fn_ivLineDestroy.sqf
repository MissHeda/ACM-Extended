/*
    Destroys a rope returned by ACME_fnc_ivLineCreate.

    Arguments:
    0: Rope object <OBJECT>

    Returns:
    true when a rope was destroyed; otherwise false.
*/
params [["_rope", objNull, [objNull]]];

if (isNull _rope) exitWith {false};

ropeDestroy _rope;
true
