/* B51: resolve the physical source capacity of a medication vial.
   ACM's Concentration tree is authoritative.  The fallback table is only a defensive bridge for live configs
   where another addon has replaced/hidden a concentration subclass even though the physical ACM_isVial item is
   still present.  Keeping this in one helper prevents the UI, vial session, infusion and debit paths from
   disagreeing about whether a carried vial contains solution. */
params [["_med", "", [""]]];
if (_med == "") exitWith {0};

private _cap = getNumber (configFile >> "ACM_Medication" >> "Concentration" >> _med >> "volume");
if (_cap > 0) exitWith {_cap};

private _fallback = missionNamespace getVariable ["ACME_vialCapacityFallback", createHashMap];
if ((count _fallback) == 0) then {
    _fallback = createHashMapFromArray [
        ["Amiodarone", 3],
        ["Atropine", 1],
        ["TXA", 10],
        ["Morphine", 2],
        ["Fentanyl", 10],
        ["Epinephrine", 1],
        ["EpinephrineCardiac", 10],
        ["Adenosine", 4],
        ["Lidocaine", 5],
        ["Ketamine", 10],
        ["Ondansetron", 2],
        ["CalciumChloride", 10],
        ["Ertapenem", 3.2],
        ["Esmolol", 10],
        ["Dimercaprol", 3],
        ["Norepinephrine", 4],
        ["Ceftriaxone", 10],
        ["CalciumGluconate", 50],
        ["Propofol", 50],
        ["Midazolam", 5],
        ["Rocuronium", 10],
        ["Sugammadex", 5],
        ["Phentolamine", 1],
        ["Hyaluronidase", 1]
    ];
    missionNamespace setVariable ["ACME_vialCapacityFallback", _fallback];
};
_fallback getOrDefault [_med, 0]
