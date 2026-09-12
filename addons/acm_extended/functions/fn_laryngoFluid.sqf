// fluid in the airway: vomitus, secretions or blood.
// call it as [] call ACME_fnc_laryngoFluid, per frame, from the tick.
// the art is 11 fill stages, 00 to 10, by 4 percolation phases per fluid. the two run on separate timers, which is
// the whole trick: the surface keeps moving at its own rate whatever the level is doing, so a pool that is
// sitting still still looks alive, and one that is filling does not speed up its own ripple just because it is
// rising. the rates are from the supplied table.
// resting percolation is a phase of 120 to 140 ms with the fill held.
// active vomiting is a phase of 70 to 90 ms with a fill of plus 1 every 100 to 150 ms.
// secretions are a phase of 120 to 140 ms with a fill of plus 1 every 800 to 1500 ms.
// blood is a phase of 120 to 140 ms with a fill of plus 1 every 500 to 1200 ms.
// suctioning secretions is a phase of 100 to 130 ms with a fill of minus 1 every 120 to 200 ms.
// suctioning blood is a phase of 100 to 130 ms with a fill of minus 1 every 180 to 280 ms.
// suctioning vomitus is a phase of 100 to 130 ms with a fill of minus 1 every 220 to 350 ms.
// every interval is re-rolled with about 10 percent of jitter each time it fires, so nothing reads as a mechanical
// loop. during suction the phases keep running forward, 0, 1, 2, 3, and only the fill stages reverse.
// vomiting comes in surges: it fills fast for 1 to 1.5 s, pauses 0.4 to 0.8 s, then possibly goes again.
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (isNull _dlg) exitWith {};

// pick up anything ACM has put in the airway since the last frame, so a casualty who vomits because ACM said so is
// just as messy on screen as one who vomited because we provoked them.
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
[_patient] call ACME_fnc_laryngoFluidSync;

private _kind = uiNamespace getVariable ["ACME_laryngo_fluidKind", ""];
private _ctrl = _dlg displayCtrl 87915;
if (_kind == "") exitWith { _ctrl ctrlSetTextColor [1,1,1,0]; };

private _now   = diag_tickTime;
private _stage = uiNamespace getVariable ["ACME_laryngo_fluidStage", 0];
private _phase = uiNamespace getVariable ["ACME_laryngo_fluidPhase", 0];
private _mode  = uiNamespace getVariable ["ACME_laryngo_fluidMode", "rest"];  // rest, fill or suction.
// Recheck every frame: arrest/paralysis can start while a fill animation is active,
// without a native fluid-state change. Keep the owner pool visible and suctionable.
private _canEmesis = !isNull _patient && {alive _patient}
    && {!(_patient getVariable ["ace_medical_inCardiacArrest", false])}
    && {!(_patient getVariable ["ACME_roc_paralyzed", false])};
if (_kind == "v" && {!_canEmesis} && {_mode == "fill"}) then {
    _stage = uiNamespace getVariable ["ACME_laryngo_fluidCap", _stage];
    _mode = "rest";
    uiNamespace setVariable ["ACME_laryngo_fluidStage", _stage];
    uiNamespace setVariable ["ACME_laryngo_fluidMode", _mode];
};

private _jit = { params ["_lo","_hi"]; (_lo + (random (_hi - _lo))) / 1000 };

// the phase timer: the surface moving.
if (_now >= (uiNamespace getVariable ["ACME_laryngo_fluidPhaseNext", 0])) then {
    _phase = (_phase + 1) % 4;
    uiNamespace setVariable ["ACME_laryngo_fluidPhase", _phase];
    private _g = switch (_mode) do {
        case "fill":    { if (_kind == "v") then { [70, 90] } else { [120, 140] } };
        case "suction": { [100, 130] };
        default         { [120, 140] };
    };
    uiNamespace setVariable ["ACME_laryngo_fluidPhaseNext", _now + (_g call _jit)];
};

// the fill timer: the level rising or falling.
if (_now >= (uiNamespace getVariable ["ACME_laryngo_fluidFillNext", 0])) then {
    switch (_mode) do {
        case "fill": {
            // vomiting surges rather than pouring steadily: a fast run, then a pause, then maybe another.
            if (_kind == "v" && {_now >= (uiNamespace getVariable ["ACME_laryngo_fluidSurgeEnd", 0])}) then {
                if (_now >= (uiNamespace getVariable ["ACME_laryngo_fluidPauseEnd", 0])) then {
                    uiNamespace setVariable ["ACME_laryngo_fluidSurgeEnd", _now + 1 + (random 0.5)];
                    uiNamespace setVariable ["ACME_laryngo_fluidPauseEnd", _now + 1.5 + (random 0.8)];
                };
            };
            private _paused = (_kind == "v")
                && {_now > (uiNamespace getVariable ["ACME_laryngo_fluidSurgeEnd", 0])}
                && {_now < (uiNamespace getVariable ["ACME_laryngo_fluidPauseEnd", 0])};
            // a capped fill stops where it was told to. a scrape bleeds a little and does not fill the mouth.
            private _cap = uiNamespace getVariable ["ACME_laryngo_fluidCap", 10];
            if (!_paused) then { _stage = (_stage + 1) min _cap min 10; };
            private _g = switch (true) do {
                // a persistent bleed builds slowly. it is spread over persistfill seconds across the stages up to its cap, so it
                // seeps back rather than surging, and there is room to work while it does.
                case ((_kind == "b") && {uiNamespace getVariable ["ACME_laryngo_fluidPersist", false]}): {
                    private _cap = (uiNamespace getVariable ["ACME_laryngo_fluidCap", 4]) max 1;
                    private _ms = ((missionNamespace getVariable ["ACME_laryngo_persistFill", 15]) / _cap) * 1000;
                    [_ms * 0.85, _ms * 1.15]
                };
                case (_kind == "v"): { [100, 150] };
                case (_kind == "b"): { [500, 1200] };
                default             { [800, 1500] };
            };
            uiNamespace setVariable ["ACME_laryngo_fluidFillNext", _now + (_g call _jit)];
            if (_stage >= ((uiNamespace getVariable ["ACME_laryngo_fluidCap", 10]) min 10)) then { uiNamespace setVariable ["ACME_laryngo_fluidMode", "rest"]; };
        };
        case "suction": {
            // The physical tool alone debits the owner pool. This timer only animates its surface.
            uiNamespace setVariable ["ACME_laryngo_fluidFillNext", _now + 0.25];
        };
        default {
            uiNamespace setVariable ["ACME_laryngo_fluidFillNext", _now + 0.25];
        };
    };
    uiNamespace setVariable ["ACME_laryngo_fluidStage", _stage];
};

// a casualty who vomits around an unsecured tube expels it. only a tube that is fully seated with the cuff up
// survives, because that is the point at which it is physically held in the trachea.
// it fires once per vomit rather than every frame the vomit lasts.
if (_kind == "v" && {_mode == "fill"} && {_canEmesis}) then {
    if (!(uiNamespace getVariable ["ACME_laryngo_ejectedThisVomit", false])) then {
        uiNamespace setVariable ["ACME_laryngo_ejectedThisVomit", true];
        ["vomit"] call ACME_fnc_laryngoTubeEject;
    };
} else {
    if (_kind != "v") then { uiNamespace setVariable ["ACME_laryngo_ejectedThisVomit", false]; };
};

if (_stage <= 0 && {_mode != "fill"}) exitWith { _ctrl ctrlSetTextColor [1,1,1,0]; };

// a two-digit stage, built by hand rather than leaning on a formatting helper.
// the stage is a float. the wand clears in whole steps so it happened to hold integers, but the bulb subtracts a
// fractional amount per squeeze, and a stage of 3.17 built the filename v_03.17_0.paa, which does not exist.
// it is rounded to a frame here. anything above zero renders at least frame 01, so the last of a fluid is still
// drawn rather than vanishing before it is cleared.
private _si = (ceil _stage) max 1 min 10;
if (_stage <= 0) then { _si = 0 };
private _ss = if (_si < 10) then { format ["0%1", _si] } else { "10" };
_ctrl ctrlSetText (format ["\acm_extended\ui\laryngo\fluid\%1_%2_%3.paa", _kind, _ss, _phase]);
_ctrl ctrlSetTextColor [1, 1, 1, 1];
