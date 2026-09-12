// add an always-on, color-coded skin-pallor row to the medical-menu injury list.
// it is the outward skin sign, shown in every state from healthy through dead, the same way cyanosis is graded.
// it hooks the pre-render event of ACM, ace_medical_gui_updateInjuryListWounds, and _woundEntries is by-reference so
// pushing adds a rendered row. it is shown on every body-part view, so it is never missed.
// _this is [_ctrl, _target, _selectionN, _woundEntries, _bodyPartName].
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN < 0}) exitWith {};
if !(missionNamespace getVariable ["ACME_skin_showRow", true]) exitWith {};

(_target call ACME_fnc_skinSigns) params ["_short", "", "_rgba"];
_woundEntries pushBack [_short, _rgba];
