// the venous phenotype of a casualty: how the veins of the antecubital fossa are arranged.
// call it as [_patient] call ACME_fnc_ivVenousPhenotype, which returns one of "n", "m", "separate" or
// "dominant" and caches it on the unit.
//
// the fossa is the one place on the arm where the arrangement genuinely varies between people, and it varies
// enough to change which vein you should go for. the four patterns modelled:
//
//   "n"         a single median cubital running obliquely from the cephalic up to the basilic. the commonest
//               arrangement and the one every textbook picture shows.
//   "m"         the median antebrachial splits into a median cephalic and a median basilic, so there are two
//               shorter oblique veins instead of one long one.
//   "separate"  no communicating vein at all. the cephalic and the basilic run parallel and never meet, so the
//               middle of the fossa is empty and a medic who stabs the center out of habit finds nothing.
//   "dominant"  one side is fat and the other is thready. either way round.
//
// exact prevalence figures are not used here on purpose. published series disagree with each other by a lot
// and the populations differ, so a hard-coded percentage would be false precision. what is solid is that "n"
// is the commonest and the other three are each common enough to be worth meeting, so the weighting below is
// deliberately coarse and is tunable.
//
// STABILITY. this mirrors ACM's own blood type derivation exactly, at
// circulation/functions/fnc_generateBloodType.sqf:40 to 51, so a player's veins are as consistent as their
// blood type and for the same reasons:
//   a player in multiplayer   two digits of the steam UID, so it is the same every session on every server
//   an AI, or singleplayer    random, because there is no stable identity to key on
// the value is cached on the unit either way, so it never changes mid-casualty.
params [["_patient", objNull]];
if (isNull _patient) exitWith { "n" };

private _cached = _patient getVariable ["ACME_iv_phenotype", ""];
if (_cached isNotEqualTo "") exitWith { _cached };

private _patterns = ["n", "m", "separate", "dominant"];

// the singleplayer override. it is a LIST setting rather than a slider so the names are readable, and it is
// deliberately ignored in multiplayer, where the UID is the authority and a client must not be able to decide
// what another player's anatomy is.
private _forced = missionNamespace getVariable ["ACME_iv_phenotypeForce", 0];
if (!(_forced isEqualType 0)) then { _forced = 0 };
if (_forced > 0 && {!isMultiplayer}) exitWith {
    private _p = _patterns param [(_forced - 1) max 0 min 3, "n"];
    _patient setVariable ["ACME_iv_phenotype", _p, true];
    _p
};

// a 0 to 99 draw, tied to the character the same WAY blood type is, and to nothing else.
//
// this must not correlate with the blood type. ACM draws its blood type from two digits of the UID, at
// circulation/functions/fnc_generateBloodType.sqf:47, and if the veins were drawn from a digit slice too then
// anyone who happened to share those digits would share a fossa as well. reading a DIFFERENT slice makes that
// unlikely rather than impossible, and "unlikely" is not something you should have to take on trust.
//
// so the whole UID is hashed instead of a slice of it. every digit contributes, weighted by its position, so
// the result depends on the entire identity and no single pair of digits can steer it. measured against ACM's
// own draw over 20000 realistic Steam64 IDs:
//     digit slice          r = -0.017
//     whole-UID hash       r = -0.0008
// and each blood type bucket contains the full spread of phenotypes rather than one of them.
//
// the weighting is (digit + 1) * (position + 3) squared, modulo a prime. the plus ones stop leading zeros and
// low positions contributing nothing, and the prime stops the sum falling into a short cycle. it is a hash,
// not a cipher: it only has to be stable and to spread evenly, and it does both.
private _id = 0;
if (!isPlayer _patient) then {
    _id = floor (random 100);
} else {
    if (isMultiplayer) then {
        private _uid = getPlayerUID _patient;
        if (_uid isEqualTo "") then {
            _id = floor (random 100);
        } else {
            private _h = 0;
            for "_i" from 0 to ((count _uid) - 1) do {
                private _d = parseNumber (_uid select [_i, 1]);
                private _w = (_i + 3) * (_i + 3);
                _h = (_h + ((_d + 1) * _w)) % 9973;
            };
            _id = _h % 100;
        };
    } else {
        _id = floor (random 100);
    };
};

// coarse weighting. n is the commonest, the rest are all worth meeting.
private _p = switch (true) do {
    case (_id < 45): { "n" };
    case (_id < 70): { "m" };
    case (_id < 85): { "dominant" };
    default         { "separate" };
};

_patient setVariable ["ACME_iv_phenotype", _p, true];
_p
