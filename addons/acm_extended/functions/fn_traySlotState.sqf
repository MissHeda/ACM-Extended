/* Render a stationary tray logo; the held/placed sprite remains a separate control.
   Reusing the exact logo preserves its alpha mask without another control or hitbox.
   A depleted slot retains its silhouette after pickup until stock is replenished.
   Fresh empty slots keep the existing dimmed artwork. All state is display-local. */
disableSerialization;
params [
    ["_icon", controlNull, [controlNull]],
    ["_removed", false, [false]],
    ["_stock", 1, [0]],
    ["_visible", true, [false]],
    ["_occupiedAlpha", 1, [0]]
];
if (isNull _icon) exitWith {};
private _vacant = _removed || {_stock <= 0 && {_icon getVariable ["ACME_TrayTaken", false]}};
_icon setVariable ["ACME_TrayTaken", _vacant];
_icon ctrlSetTextColor (if (_vacant) then {[0, 0, 0, 1]} else {
    [1, 1, 1, if (_stock > 0) then {_occupiedAlpha} else {0.25}]
});
_icon ctrlShow _visible;
