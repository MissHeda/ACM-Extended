/* B13: fail closed before inventory consumption and again on the patient owner.
   Fixed-dose PO/inhaled/buccal products retain their native non-IV route.
   Phentolamine/hyaluronidase use local infiltration, never systemic IV delivery. */
params ["_class", ["_iv", false], ["_injectableOnly", false], ["_preparedMixture", false]];
if !(_class isEqualType "" && {_iv isEqualType true}) exitWith {false};
// B38 prepared syringes permit any configured injectable source on the selected
// injection route. Native treatment actions retain their original route gates.
if (_preparedMixture isEqualTo true) exitWith {
    private _source = (_class splitString "_") param [0, ""];
    private _cfg = configFile >> "ACM_Medication" >> "Medications" >> _class;
    private _sourceCfg = configFile >> "ACM_Medication" >> "Concentration" >> _source;
    _class in [_source, _source + "_IV"] && {isClass _cfg}
        && {getNumber (_cfg >> "administrationType") in [0, 1]}
        && {getNumber (_sourceCfg >> "concentration") > 0}
        && {getNumber (_sourceCfg >> "volume") > 0}
};
if (_class in ["EpinephrineCardiac", "EpinephrineCardiac_IV"]) exitWith {_iv};
if (_class in ["Adenosine", "Amiodarone", "Rocuronium", "Phentolamine_IV", "Hyaluronidase_IV"]) exitWith {false};
private _cfg = configFile >> "ACM_Medication" >> "Medications" >> _class;
if (!isClass _cfg) exitWith {false};
private _route = getNumber (_cfg >> "administrationType");
if (_injectableOnly && {!(_route in [0,1]) || {_class == "Fentanyl_BUC"}}) exitWith {false};
(_route == 1) isEqualTo _iv
