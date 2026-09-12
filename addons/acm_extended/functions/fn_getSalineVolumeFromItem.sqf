params ["_itemClass", ["_actionClass", ""]];

// the carrier, meaning crystalloid, volume in ml.
// ACM stores the volume of a hung bag from the "volume" config of the action class, so SalineIV_100 gives 100,
// PlasmaLyteIV_250 gives 250 and MannitolIV_500 gives 500. findNewestBagContext matches the freshly-hung bag
// against this number, so it must be exact.
// parse the trailing numeric size token from the action class, then the item class, accepting any pure-number token.
// the old version only special-cased 250 and 500 and defaulted everything else to 1000, so 100 ml and 50 ml bags
// resolved to 1000 and never matched their own bag. the medication was therefore never attached and the bag stayed
// a plain fluid in the transfusion menu.
private _fnc_trailNum = {
    params ["_s"];
    private _best = -1;
    {
        private _n = parseNumber _x;
        if (_n > 0 && {(str (round _n)) == _x}) then { _best = round _n; };  // pure-number token only (rejects "16G", "salineIV", etc.)
    } forEach (_s splitString "_ -");
    _best
};

private _fromAction = [_actionClass] call _fnc_trailNum;
private _fromItem   = [_itemClass] call _fnc_trailNum;
private _volume = _fromAction;
if (_volume <= 0) then { _volume = _fromItem; };
private _defaulted = false;
if (_volume <= 0) then { _volume = 1000; _defaulted = true; };
_volume
