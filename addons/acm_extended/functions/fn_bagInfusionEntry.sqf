// the one and only bag into infusion-entry matcher. both the "Adjust Infusion" readout and the infusions sub-list
// must use this, so they can never disagree. the divergence between two near-identical inline matchers is exactly
// why an infusion could vanish from the list while adjust still found it.
// given a patient, the selected body part and a single bag row from transfusionmenu_selection_ivbags, it returns
// the matching drug entry from ACME_infusion_BagMedications, or [] if this bag carries no active infusion.
// matching is identity-first, on the body part, fluid type, iv or io, blood type, nominal volume and fresh-blood
// id, because handleinfusions rewrites the bagindex of an entry every tick. so the bagindex and access site can
// only ever be a tie-breaker between two otherwise-identical bags, never a requirement. an exact bagindex plus
// site match wins over a looser identity-only match when both are present.
// call it as [_patient, _bodyPart, _bagRow, _entries, _claimed] call ACME_fnc_bagInfusionEntry, which returns
// [_entry, _entryIndex] or [].
// _bagRow is [type, remaining, accesstype, accesssite, iv, bloodtype, volume, freshbloodid, trueindex].
// _entries is ACME_infusion_BagMedications, passed in so callers can share one read.
// _claimed is an optional array of already-claimed entry indices to skip, for one-to-one binding across many bags.
// pass [], or omit it, when you just want the best match for a single bag.
params ["_patient", "_bodyPart", "_bagRow", ["_entries", nil], ["_claimed", []]];
if (isNil "_entries") then { _entries = _patient getVariable ["ACME_infusion_BagMedications", []]; };

_bagRow params [["_sType", ""], ["_sRemaining", 0], ["_sAccessType", 0], ["_sAccessSite", -1], ["_sIV", false], ["_sBloodType", -1], ["_sVolume", 0], ["_sFreshBloodID", -1], ["_sTrueIndex", -1]];

private _bestIdx = -1;
private _bestExact = false;
{
    if !(_forEachIndex in _claimed) then {
        _x params ["", "_eBodyPart", "_eBagIndex", "_eType", "_eAccessSite", "_eIV", "_eBloodType", "_eVolume", "_eFreshBloodID"];
        private _identity = (toLowerANSI _eBodyPart == toLowerANSI _bodyPart)
            && {_eType == _sType} && {_eIV == _sIV} && {_eBloodType == _sBloodType}
            && {_eVolume == _sVolume} && {_eFreshBloodID == _sFreshBloodID};
        if (_identity) then {
            private _exact = (_eBagIndex == _sTrueIndex) && {_eAccessSite == _sAccessSite};
            if (_exact) then {
                // an exact match is authoritative: take it and stop.
                _bestIdx = _forEachIndex;
                _bestExact = true;
            } else {
                // keep the first identity-only match, unless we already hold an exact one.
                if (!_bestExact && {_bestIdx < 0}) then { _bestIdx = _forEachIndex; };
            };
        };
    };
} forEach _entries;

if (_bestIdx < 0) exitWith {[]};
[_entries select _bestIdx, _bestIdx]
