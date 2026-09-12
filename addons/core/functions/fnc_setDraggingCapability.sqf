#include "..\script_component.hpp"
/*
 * Author: ACM Extended Fork
 * Core-owned ACE dragging integration boundary. The ACE dragging addon intentionally exposes these object flags;
 * keeping the publication here prevents Extended feature code from owning ACE capability state directly.
 */
params [
    ["_object", objNull, [objNull]],
    ["_canDrag", true, [true]],
    ["_canCarry", true, [true]],
    ["_public", true, [true]]
];
if (isNull _object) exitWith {false};
_object setVariable ["ace_dragging_canDrag", _canDrag, _public];
_object setVariable ["ace_dragging_canCarry", _canCarry, _public];
true
