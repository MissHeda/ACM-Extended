// open the blood cooler the player is carrying, from the ACE self-interaction menu.
// it finds the first cooler class present in the items of the player and opens its manager dialog. if more than one
// cooler is carried we simply open the first found, because the dialog manages one cooler class at a time,
// coolers of the same class share a contents pool, and carrying two different classes at once is a rare edge.
// it returns quietly with a hint if none is carried. the menu condition should already gate this, and we guard
// anyway.
private _coolers = ["ACME_BloodCooler_CSWB1U", "ACME_BloodCooler_CSWB2U", "ACME_BloodCooler_CSWB4U"];
private _items = items ACE_player;  // all carried items (uniform/vest/backpack), classnames
private _have = "";
{
    if (_x in _items) exitWith { _have = _x; };
} forEach _coolers;

if (_have == "") exitWith {
    ["No blood cooler in your kit.", 2, ACE_player] call ace_common_fnc_displayTextStructured;
};

[_have] call ACME_fnc_coolerOpenDialog;
