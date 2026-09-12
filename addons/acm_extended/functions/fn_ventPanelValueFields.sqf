// the value fields. it splits a list row into a label that never lights and a value that does.
// the problem this solves: a list row is one control carrying one string, such as "LOW RR        6 BPM". so when
// the cursor lands on it, the highlight has no choice but to swallow the whole row, the label included. on a real
// ventway that is not what happens. the label is printed on the screen and stays printed, and the number is what
// inverts, because the number is the only thing you are about to change. highlighting the label as well tells the
// medic that "LOW RR" is editable, which it is not.
// it also matters for reading speed, which is the actual point of a device like this. in a shaking cabin, at night,
// you are looking for one number. if five whole rows can light up, your eye has to parse the row to find the
// value, and if only the value lights, your eye goes straight to it.
// so the row control keeps the label and is never colored, and a value control is created over the right-hand end
// of the row, carrying the number and its unit, and it is the only thing that takes the highlight.
// call it as [[["LOW RR", "6 BPM"], ["HIGH RR", "25 BPM"], ...]] call ACME_fnc_ventPanelValueFields.
// pass a value of "" for a row that has no value, meaning a plain menu row. it simply gets no field.
params [["_pairs", []]];
disableSerialization;

private _dlg = uiNamespace getVariable ["ACME_vent_dlg", displayNull];
if (isNull _dlg) exitWith {};

// tear down the fields of the last screen. these are created per screen, so they must die per screen or they will
// hang over the next one. the ventilator has already been bitten once by controls outliving the screen that made
// them.
{ if (!isNull _x) then { ctrlDelete _x; }; } forEach (uiNamespace getVariable ["ACME_vent_valFields", []]);
uiNamespace setVariable ["ACME_vent_valFields", []];

if (_pairs isEqualTo []) exitWith {};

private _rowIdc = [87781, 87782, 87783, 87784, 87785, 87786];
private _split  = missionNamespace getVariable ["ACME_vent_valueSplit", 0.56];  // where the value column starts.
private _fields = [];
// the row font, explicitly. fields used to render at the default button size of the engine, an unpinned number that
// has burned this panel repeatedly. the target is the list-row size, _sh times 0.13, the size every menu on the
// panel already uses, capped by the height of the field itself and by what actually fits the column width for
// this string, estimated at 0.5 font-heights per character, so "40 cmH2O" shrinks a touch instead of
// clipping.
(uiNamespace getVariable ["ACME_vent_scrRect", [0,0,1,1]]) params ["", "", "", "_sh"];

{
    _x params [["_label", ""], ["_value", ""]];
    private _i = _forEachIndex;
    if (_i > 5) exitWith {};

    private _row = _dlg displayCtrl (_rowIdc select _i);
    if (isNull _row) then { continue };

    // the row carries the label only now. it will never be colored again.
    _row ctrlSetText _label;

    if (_value isEqualTo "") then {
        _fields pushBack controlNull;  // keep the array index-aligned with the rows.
        continue;
    };

    (ctrlPosition _row) params ["_rx", "_ry", "_rw", "_rh"];

    // the field hugs the value. it starts where the value column starts and runs to the end of the row, so the
    // highlight is a block around the number rather than a stripe across the screen.
    private _fx = _rx + (_rw * _split);
    private _fw = _rw * (1 - _split);

    private _f = _dlg ctrlCreate ["ACME_VentValG", -1];
    _f ctrlSetPosition [_fx, _ry, _fw, _rh];
    _f ctrlSetFontHeight (((_sh * 0.13) min _rh) min (_fw / (0.5 * ((count _value) max 1))));
    _f ctrlSetText _value;
    _f ctrlSetBackgroundColor [0, 0, 0, 0];
    _f ctrlSetTextColor [0.92, 0.92, 0.92, 1];
    _f ctrlCommit 0;
    _f ctrlShow true;

    _fields pushBack _f;
} forEach _pairs;

uiNamespace setVariable ["ACME_vent_valFields", _fields];
