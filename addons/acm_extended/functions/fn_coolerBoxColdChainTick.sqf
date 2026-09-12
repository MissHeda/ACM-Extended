// a server-side pass over deployed cooler boxes: the box equivalent of fn_coolercontentstick. while the coolant of
// a box lasts, its blood is preserved with no aging. once the coolant expires, the insulated box still slows the
// thaw, so the blood lasts far longer than a loose bag, and it does eventually spoil into spoiled blood inside the
// box.
// it runs on the server because box blood is real shared cargo rather than a per-player virtual store, and spoilage
// rewrites that cargo with the *global cargo commands.
// box blood is real cargo with no per-bag timer, so a box tracks one warm clock for all of its units: they are all
// kept cold together while the coolant lasts and, once it is gone, all cross the shelf life together. the time
// elapsed is read from ACME_boxCoolantStart, carried across the deploy and pick-up, so the math is stateless and
// the tick interval does not affect when blood spoils.
if !(missionNamespace getVariable ["ACME_sys_bloodChain", true]) exitWith {};  // the system toggle. fully off means this stops.
if (!isServer) exitWith {};
if !(missionNamespace getVariable ["ACME_bloodSpoilEnabled", true]) exitWith {};

private _spoilT = missionNamespace getVariable ["ACME_bloodLooseSpoilTime", 1200];
private _thawIn = missionNamespace getVariable ["ACME_coolerThawRateInside", 0.2];  // the same slow inside-thaw the carried cooler uses.

private _boxes = (allMissionObjects "ACME_BloodCoolerBox_CSWB1U")
              + (allMissionObjects "ACME_BloodCoolerBox_CSWB2U")
              + (allMissionObjects "ACME_BloodCoolerBox_CSWB4U");
{
    private _box = _x;

    // which cooler item does this box correspond to, for its cold-chain duration? prefer the stamp and fall back to the
    // box class, so editor-placed boxes still age.
    private _itemClass = _box getVariable ["ACME_boxCoolerClass", ""];
    if (_itemClass == "") then {
        _itemClass = switch (typeOf _box) do {
            case "ACME_BloodCoolerBox_CSWB1U": { "ACME_BloodCooler_CSWB1U" };
            case "ACME_BloodCoolerBox_CSWB2U": { "ACME_BloodCooler_CSWB2U" };
            case "ACME_BloodCoolerBox_CSWB4U": { "ACME_BloodCooler_CSWB4U" };
            default { "" };
        };
    };
    if (_itemClass != "") then {
        private _chain = getNumber (configFile >> "CfgWeapons" >> _itemClass >> "ACME_coolerColdChainTime");
        if (_chain > 0) then {
            private _start = _box getVariable ["ACME_boxCoolantStart", time];
            // only past coolant expiry does anything age. while cold, blood is simply preserved.
            if ((time - _start) >= _chain) then {
                // the effective warm time since the coolant ran out, slowed by the insulated box, against 1.0 loose.
                private _effWarm = (time - (_start + _chain)) * _thawIn;
                if (_effWarm >= _spoilT) then {
                    private _cargo = itemCargo _box;
                    private _spoilCount = { (_x find "ACM_BloodBag_") == 0 } count _cargo;
                    if (_spoilCount > 0) then {
                        // replace every blood bag with the same number of spoiled blood, and leave any non-blood cargo.
                        private _kept = _cargo select { (_x find "ACM_BloodBag_") != 0 };
                        clearItemCargoGlobal _box;
                        { _box addItemCargoGlobal [_x, 1]; } forEach _kept;
                        _box addItemCargoGlobal ["ACME_SpoiledBlood", _spoilCount];
                        // tell anyone standing near the box.
                        {
                            [format ["%1 blood unit(s) in a cooler lost the cold chain and spoiled.", _spoilCount], 3] remoteExec ["ace_common_fnc_displayTextStructured", _x];
                        } forEach (allPlayers select { (_x distance _box) < 12 });
                    };
                };
            };
        };
    };
} forEach _boxes;
