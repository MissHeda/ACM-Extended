// the access site index ACM uses, from the site name the mini-game uses.
// call it as [_site] call ACME_fnc_ivSiteIndex, which returns 0 for upper, 1 for middle and 2 for lower.
//
// this existed as seven separate copies, and they did not agree. the copy in fn_ivminigameregister mapped the
// two ej sites and defaulted to lower. the copy in fn_ivminigamepullstop mapped neither and defaulted to middle.
// so an ej line registered at one index and a pull cleared a different one, which left the pulled line in place
// and removed a good line somewhere else on the same limb.
// one mapping, one file. a site that is not recognized returns lower, which is what registration always did.
params [["_site", "lower"]];
if (_site isEqualType 0) exitWith { (round _site) max 0 min 2 };

// THIS LINE HELD THE FAULT. It read "switch (toLower (str _site))".
// str adds quotation marks to a string. str "middle" returns the six characters """middle""".
// No case below can match that, so EVERY site name fell through to the default and returned 2.
// The mini game resolved the correct site, the log named the correct vein, and this function then
// gave ACM the lower access site for every IV on every limb.
// _site is a string at this point, because the number test above returns first. Do not convert it.
if !(_site isEqualType "") exitWith { 2 };

switch (toLower _site) do {
    case "upper":  { 0 };
    case "middle": { 1 };
    case "lower":  { 2 };
    // the ej carries a side rather than a height, and it is filed against the first two indices.
    case "left":   { 0 };
    case "right":  { 1 };
    default { 2 };
};
