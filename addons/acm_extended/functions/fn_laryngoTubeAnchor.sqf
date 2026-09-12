// what is holding the tube, and how hard.
// call it as [] call ACME_fnc_laryngoTubeAnchor, which returns [_locked, _resist, _reason].
// _locked at true means it cannot move at all. _resist is 0 to 1, how much of a scroll gets eaten before the tube
// moves. _reason is what to tell the medic if they try.
// three things can hold a tube, and they are not the same thing.
// the collar is a strap around the head and the tube. it is mechanical, absolute, and the entire reason it is there.
// while it is on, the tube does not move. take it off first. there is no resistance model and nothing partial.
// the cuff is an inflated balloon sitting in the trachea, below the cords. this is the one that matters, because it
// does not feel like a lock. it feels like the tube is jointed at the cords: it will give a little, it tugs back,
// and if you keep pulling it drags an inflated balloon through the vocal cords, which tears them. that is the mild
// bleeding. the cuff must come down first, and there are no exceptions to that in life either.
// nothing, meaning the cuff is down and the collar is off, and the tube slides.
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
private _pat = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
if (isNull _pat) exitWith { [false, 0, ""] };

if (_pat getVariable ["ACME_ETT_Secured", false]) exitWith {
    [true, 1, "The collar is holding it. Take the collar off first."]
};

if (_pat getVariable ["ACME_ETT_CuffInflated", false]) exitWith {
    [false, (missionNamespace getVariable ["ACME_ETT_cuffResist", 0.88]),
     "The cuff is up. Deflate it before you move the tube."]
};

[false, 0, ""]
