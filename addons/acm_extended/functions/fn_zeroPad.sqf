// left-pad a number with zeroes to a fixed width, and return it as a string.
// call it as [7, 4] call ACME_fnc_zeroPad, which returns "0007".
// the suction bag frames are named with fixed-width numbers, such as nar_tsd_level_0050_ca.paa and _f01_ca.paa, so a
// filename built with a plain str would ask for _50_ and _f1_ and find nothing. this exists so that cannot
// happen.
params ["_n", ["_w", 2]];
private _s = str (round _n);
while {(count _s) < _w} do { _s = "0" + _s; };
_s
