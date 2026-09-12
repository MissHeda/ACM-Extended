/* Show the current CBA bindings. An unbound action stays unbound. */
disableSerialization;
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};
if (diag_tickTime < (_display getVariable ["ACME_InputHintNext", -1])) exitWith {};
_display setVariable ["ACME_InputHintNext", diag_tickTime + 0.5];
private _labels = [];
{
    if ((_x select 0) != "flip") then {continue;};
    (_x select 1) params ["_key","_device"];
    private _mods = _x select 4;
    private _parts = [];
    if (_mods select 0) then {_parts pushBack "Shift";};
    if (_mods select 1) then {_parts pushBack "Ctrl";};
    if (_mods select 2) then {_parts pushBack "Alt";};
    private _label = switch (_device) do {
        case "MOUSE_BUTTON": {format ["Mouse %1", _key + 1]};
        case "ACME_WHEEL": {["Wheel Up","Wheel Down"] select _key};
        default {keyName _key};
    };
    _parts pushBack _label;
    _labels pushBack (_parts joinString "+");
} forEach ([_display] call ACME_fnc_minigameInputBindings);
private _label = if (_labels isEqualTo []) then {"Unbound"} else {_labels joinString " / "};
private _control = _display displayCtrl 87777;
if (!isNull _control) then {_control ctrlSetText (_label + ": Flip Device");};
