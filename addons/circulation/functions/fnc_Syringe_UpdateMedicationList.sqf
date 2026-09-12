/* B43: one authoritative medication-row builder owns both the hidden ACM list and the visible Narc Box.
   Do not independently reconstruct rows here; split ownership was the source of the repeated-drug regression. */
disableSerialization;
private _display = uiNamespace getVariable ["ACM_circulation_SyringeDraw_DLG", displayNull];
if (isNull _display) exitWith {};
[_display] call ACME_fnc_skMedicationSync;
