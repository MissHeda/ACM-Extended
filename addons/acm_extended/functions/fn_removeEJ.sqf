// remove an established ej iv. an ej is modeled as a head iv on ACM access site 0, the left jugular, or 1, the
// right.
// the removal mirrors the placement but writes type 0 to the access site, which is the no-iv marker of ACM. the
// setivlocal of ACM then also returns any hung bag to the medic, through its _type==0 branch.
// the body-diagram overlay, fn_updateejimage, reads the same ACM iv state, so it clears on its own. it removes
// whichever jugulars are cannulated.
// call it as [_medic, _patient] call ACME_fnc_removeEJ.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};

private _ivArr = _patient getVariable ["ACM_circulation_IV_Placement", []];
private _head  = if ((count _ivArr) > 0 && {(_ivArr select 0) isEqualType []}) then { _ivArr select 0 } else { [] };

private _removed = false;
{
    private _site = _x;
    private _type = _head param [_site, 0];
    if ((_type isEqualType 0) && {_type > 0}) then {
        // type 0 clears this access site. it is routed through the patient so the state and the bag return replicate.
        ["ACM_circulation_setIVLocal", [_medic, _patient, "head", 0, true, _site], _patient] call CBA_fnc_targetEvent;
        _removed = true;
    };
} forEach [0, 1];

if (_removed) then {
    playSound "ACE_Sound_Click";
    // the jugular overlay on the body diagram is driven by the "ace_medical_gui_updateBodyImage" event of ACE, because
    // it needs the live body-image controls group, which only exists inside the menu. clearing the ACM iv state above
    // makes that handler hide the icon on the next body-image redraw, so we do not call the overlay directly here.
} else {
    ["No EJ IV to remove.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
