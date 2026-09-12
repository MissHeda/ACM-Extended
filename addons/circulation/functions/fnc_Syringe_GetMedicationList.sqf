/* B53: return the physical medication classes represented by the authoritative row builder.
 * Native ACM asks this function repeatedly while the syringe dialog is open, so its mode discriminator must be the
 * same display-local return route used by ACME_fnc_skMedicationSync. A stale mission-level infusion pendingContext
 * must never make a normal Narc Box report a different list length than the list actually being displayed.
 */
params [];
private _display = uiNamespace getVariable ["ACM_circulation_SyringeDraw_DLG", displayNull];
private _infusion = false;
if (!isNull _display) then {
    _infusion = !((_display getVariable ["ACME_SK_Return", []]) isEqualTo []);
};

private _rows = [_infusion] call ACME_fnc_medicationSourceRows;
private _classes = [];
{
    if !(_x isEqualType []) then {continue};
    private _class = _x param [3, ""];
    if (_class isEqualType "" && {_class != ""}) then {_classes pushBack _class;};
} forEach _rows;
_classes
