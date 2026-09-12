// generate the label for a drawn compound or waste syringe. given the syringe capacity and the list of components,
// each [medication, ml], plus any saline volume, this recognizes the named products by their exact expected
// recipe and returns the nice name. anything else gets a generic "AmL X / BmL Y (/ NmL NS)" label. the
// correctness of the recipe is on the medic: only an exact match earns the name.
// call it as [_capMl, _components, _nsMl] call ACME_fnc_skCompoundLabel.
// _capMl is the syringe capacity in ml. ketofol is 10 ml only.
// _components is an array of [medication, a string, and volumeml, a number] in draw order.
// _nsMl is the saline volume in the barrel, and 0 for a pure compound.
// it returns the label as a string.
params [["_capMl", 10], ["_components", []], ["_nsMl", 0]];

private _tol = 0.25;  // the ml tolerance for matching an expected volume, allowing for partial-pull slop.
private _fnc_near = { params ["_a", "_b"]; (abs (_a - _b)) <= _tol };

// a helper: the total ml of a given drug across the components.
private _fnc_vol = {
    params ["_drug"];
    private _v = 0;
    { _x params ["_m", "_ml"]; if (_m == _drug) then { _v = _v + _ml }; } forEach _components;
    _v
};

private _drugs = _components apply { _x select 0 };
private _nDrugs = count _drugs;

// Cardiac-strength source only. A full mixture contains 100 mcg, not a single 10 mcg dose.
if (_nDrugs == 1 && {[(_drugs select 0), _capMl, [(_drugs select 0)] call _fnc_vol, _nsMl] call ACME_fnc_epinephrineRecipe}) exitWith {
    "Push-dose epinephrine 10 mcg/mL (10 mL = 100 mcg)"
};

// ketofol is a 10 ml syringe with 5 ml of ketamine plus 5 ml of propofol and no saline.
if (
    [_capMl, 10] call _fnc_near &&
    {_nDrugs == 2} &&
    {"Ketamine" in _drugs} && {"Propofol" in _drugs} &&
    {[["Ketamine"] call _fnc_vol, 5] call _fnc_near} &&
    {[["Propofol"] call _fnc_vol, 5] call _fnc_near} &&
    {_nsMl <= _tol}
) exitWith {
    "Ketamine 250 mg + propofol 50 mg (10 mL; 5:1 mg ratio)"
};

// the generic fallback.
private _fnc_name = {
    params ["_med"];
    private _n = localize (format ["STR_ACM_Circulation_Medication_%1", _med]);
    if (_n isEqualTo "" || {_n == (format ["STR_ACM_Circulation_Medication_%1", _med])}) then { _n = _med; };
    _n
};

private _parts = [];
{
    _x params ["_m", "_ml"];
    private _dose = _ml * getNumber (configFile >> "ACM_Medication" >> "Concentration" >> _m >> "concentration");
    private _unit = if (_m == "Hyaluronidase") then {"U"} else {"mg"};
    if (_unit == "mg" && {_dose < 1}) then {_dose = _dose * 1000; _unit = "mcg";};
    _parts pushBack format ["%1 mL %2 (%3 %4)", _ml toFixed 2, [_m] call _fnc_name, _dose toFixed 2, _unit];
} forEach _components;
if (_nsMl > _tol) then { _parts pushBack format ["%1mL NS", _nsMl toFixed 1]; };

(_parts joinString " / ")
