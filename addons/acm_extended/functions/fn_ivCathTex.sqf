// build the texture path of one supercath catheter frame.
// call it as [_gauge, _frame, _index] call ACME_fnc_ivCathTex.
// _gauge is the number 14, 16, 18 or 20. _frame is the orientation suffix used everywhere else in the
// mini-game, where "" is the straight base. _index is the frame number, 0 to 14.
// the art is one silhouette per orientation in four colors, so the gauge only picks the color.
params [["_gauge", 16], ["_frame", ""], ["_index", 0]];

// the fifteen frames of the insertion sequence, in order. the names are the folder names, so they must match
// the art exactly.
private _names = [
    "00_ready",
    "01_bevel_contact",
    "02_bevel_half_cross",
    "03_bevel_crossed",
    "04_catheter_tip_cross_flash",
    "05_assembly_advance_flash",
    "06_insertion_endpoint_flash",
    "07_catheter_thread_20",
    "08_catheter_thread_40",
    "09_catheter_thread_60",
    "10_catheter_thread_80",
    "11_catheter_thread_100",
    "12_button_press_retract",
    "13_needle_captured_withdraw",
    "14_catheter_hub_only"
];

// clamp the index, so a bad caller draws the first or last frame instead of nothing.
_index = (round _index) max 0 min 14;

// only four gauges are painted. anything else falls back to 16g.
if (!(_gauge in [14, 16, 18, 20])) then { _gauge = 16; };

// the orientation folder is the frame suffix without its leading underscore. the straight frame is "base".
private _dir = if (_frame == "") then { "base" } else { _frame select [1] };

format [
    "\acm_extended\ui\iv\%1g\%2\iv_catheter_%1g_%2_frame_%3_ca.paa",
    _gauge,
    _dir,
    _names select _index
]
