// the cursor position in body-fraction, u and v, space, or [] if unavailable.
// it reuses the ultrawide-safe coord resolver of the chest seal, then maps the ui onto the body rect. u and v are 0
// to 1 on the 2048 body image, which is square, so uv distances are proportional to canvas pixels, at 2048, which
// is how the incision length converts to cm.
private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
if (count _rect != 4) exitWith { [] };
_rect params ["_bx", "_by", "_bw", "_bh"];
private _ui = [] call ACME_fnc_chestSealMouseCoords;
if (count _ui != 2) exitWith { [] };
_ui params ["_ux", "_uy"];
[(_ux - _bx) / (_bw max 1e-6), (_uy - _by) / (_bh max 1e-6)]
