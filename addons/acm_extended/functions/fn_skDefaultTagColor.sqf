params [["_med","",[""]]];
private _m=toLower _med;
if(_m in ["propofol","ketamine","etomidate"])exitWith{"yellow_induction"};
if(_m in ["midazolam","diazepam"])exitWith{"orange_benzodiazepine"};
if(_m in ["morphine","fentanyl"])exitWith{"blue_opioid"};
if(_m in ["naloxone","narcan"])exitWith{"blue_stripe_reversal"};
if(_m in ["rocuronium","succinylcholine"])exitWith{"red_paralytic"};
if(_m in ["neostigmine","sugammadex"])exitWith{"red_stripe_reversal"};
if(_m in ["epinephrine","epinephrinecardiac","norepinephrine","phenylephrine"])exitWith{"violet_vasopressor"};
if(_m in ["labetalol","hydralazine"])exitWith{"violet_stripe_hypotensive"};
if(_m in ["atropine","glycopyrrolate"])exitWith{"green_anticholinergic"};
if(_m in ["lidocaine","bupivacaine"])exitWith{"gray_local_anesthetic"};
if(_m in ["ondansetron"])exitWith{"salmon_antiemetic"};
"white_saline_flush"
