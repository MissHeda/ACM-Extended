private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
// build the lower content page of the megacode control panel for the chosen category, replacing whatever page was
// shown before. the pages are vitals, with sliders, rhythm, with the rhythm grid, airway, wounds, and neuro and
// features.
// the controls are created at runtime so the dialog config stays small, and the created controls are tracked so the
// next page switch can delete them.
// _this is [_idd, _page].
params ["_idd", "_page"];
private _disp = uiNamespace getVariable ["ACME_Megacode_DLG", displayNull];
if (isNull _disp) exitWith {};
uiNamespace setVariable ["ACME_MC_page", _page];
private _dummy = uiNamespace getVariable ["ACME_MC_target", objNull];

// wipe the previous page.
{ if (!isNull _x) then { ctrlDelete _x; }; } forEach (uiNamespace getVariable ["ACME_MC_contentCtrls", []]);
private _acc = [];
uiNamespace setVariable ["ACME_MC_contentCtrls", _acc];

private _X = _uiX; private _Y = safeZoneY; private _W = _uiW; private _H = safeZoneH;
// the same fixed-aspect centerd panel as the monitor, from panelload, so the page lines up on every aspect
// ratio.
private _pW = _H * 0.85 * 1.61;
private _pX = _X + (_W - _pW) / 2;
private _pY = _Y + _H * 0.075;
private _pH = _H * 0.85;
private _rX = _pX + 0.014; private _rW = _pW - 0.028;
private _rY = _pY + (_pH * 0.660); private _rH = _pH * 0.320;

// the builders.
private _mkLabel = {
    params ["_x","_y","_w","_h","_txt","_col","_acc","_disp"];
    private _c = _disp ctrlCreate ["RscText", -1];
    _c ctrlSetPosition [_x,_y,_w,_h]; _c ctrlSetText _txt; _c ctrlSetTextColor _col; _c ctrlCommit 0;
    _acc pushBack _c; _c
};
private _mkBtn = {
    params ["_x","_y","_w","_h","_txt","_key","_eh","_active","_acc","_disp"];
    private _b = _disp ctrlCreate ["RscButton", -1];
    _b ctrlSetPosition [_x,_y,_w,_h]; _b ctrlSetText _txt;
    _b ctrlSetBackgroundColor (if (_active) then {["selected", 1] call ACME_fnc_a11yColor} else {[0.10,0.12,0.16,1]});
    _b ctrlSetTextColor [0.92,0.95,1,1];
    _b setVariable ["mc_key", _key];
    _b ctrlAddEventHandler ["ButtonClick", _eh];
    _b ctrlCommit 0; _acc pushBack _b; _b
};
private _mkSlider = {
    params ["_x","_y","_w","_lbl","_key","_min","_max","_val","_acc","_disp"];
    private _t = [_x, _y, _w*0.42, 0.030, _lbl, [0.8,0.85,0.95,1], _acc, _disp] call (uiNamespace getVariable "ACME_MC_mkLabel");
    private _vc = _disp ctrlCreate ["RscText", -1];
    _vc ctrlSetPosition [_x + _w*0.42, _y, _w*0.16, 0.030]; _vc ctrlSetText (str (round _val)); _vc ctrlSetTextColor [1,1,1,1]; _vc ctrlCommit 0; _acc pushBack _vc;
    private _s = _disp ctrlCreate ["RscXSliderH", -1];
    _s ctrlSetPosition [_x + _w*0.42, _y + 0.026, _w*0.56, 0.022];
    _s sliderSetRange [_min, _max]; _s sliderSetPosition _val;
    _s setVariable ["mc_key", _key]; _s setVariable ["mc_valctrl", _vc];
    _s ctrlAddEventHandler ["SliderPosChanged", {
        params ["_c","_v"];
        private _vc = _c getVariable ["mc_valctrl", controlNull];
        if (!isNull _vc) then { _vc ctrlSetText str (round _v); };
        [(_c getVariable ["mc_key",""]), _v] call ACME_fnc_megacodeSetVital;
    }];
    _s ctrlCommit 0; _acc pushBack _s; _s
};
uiNamespace setVariable ["ACME_MC_mkLabel", _mkLabel];

switch (toLower _page) do {
    case "vitals": {
        private _col1 = _rX; private _col2 = _rX + _rW*0.52; private _cw = _rW*0.46;
        private _rowH = _rH/4.2;
        { _x params ["_lbl","_key","_mn","_mx","_dv"];
          private _cc = if (_forEachIndex < 4) then {_col1} else {_col2};
          private _rr = _rY + (_rowH * (_forEachIndex % 4));
          private _init = _dummy getVariable [format ["ACME_MC_%1", _key], _dv];
          if (_key == "Temp") then { _init = _init * 10; };  // it is stored in c, and the slider is c times 10.
          [_cc, _rr, _cw, _lbl, _key, _mn, _mx, _init, _acc, _disp] call _mkSlider;
        } forEach [
            ["Heart Rate","HR",0,260,78], ["SpO2","SpO2",0,100,98],
            ["Systolic BP","SBP",0,260,122], ["Diastolic BP","DBP",0,160,78],
            ["Resp Rate","RR",0,60,14], ["EtCO2","EtCO2",0,90,38],
            ["Temp x10 C","Temp",300,420,370]
        ];
    };
    case "rhythm": {
        private _cur = _dummy getVariable ["ACME_MC_rhythm","sinus"];
        private _cols = 4; private _bw = (_rW - (0.006*(_cols-1)))/_cols; private _bh = _rH/3.4;
        { _x params ["_lbl","_key"];
          private _cx = _rX + ((_forEachIndex % _cols) * (_bw + 0.006));
          private _cyr = _rY + (floor (_forEachIndex / _cols) * (_bh + 0.008));
          [_cx,_cyr,_bw,_bh,_lbl,_key, { [(_this select 0) getVariable ["mc_key",""]] call ACME_fnc_megacodeSetRhythm; }, (toLower _cur isEqualTo toLower _key), _acc, _disp] call _mkBtn;
        } forEach [
            ["Sinus","sinus"],["Sinus Tach","stach"],["Sinus Brady","sbrady"],["A-Fib","afib"],
            ["A-Fib RVR","afibrvr"],["Atrial Tach","atrialtach"],["SVT","svt"],["V-Tach","vt"],
            ["Torsades","torsades"],["V-Fib","vfib"],["Asystole","asystole"],["PEA","pea"]
        ];
    };
    case "airway": {
        private _cols = 3; private _bw = (_rW - (0.006*(_cols-1)))/_cols; private _bh = _rH/3.2;
        private _cur = _dummy getVariable ["ACME_MC_airway","patent"];
        { _x params ["_lbl","_key"];
          private _cx = _rX + ((_forEachIndex % _cols) * (_bw + 0.006));
          private _cyr = _rY + (floor (_forEachIndex / _cols) * (_bh + 0.008));
          [_cx,_cyr,_bw,_bh,_lbl,_key, { [(_this select 0) getVariable ["mc_key",""]] call ACME_fnc_megacodeSetAirway; }, (toLower _cur isEqualTo toLower _key), _acc, _disp] call _mkBtn;
        } forEach [
            ["Patent","patent"],["Blood Obstruction","blood"],["Vomit Obstruction","vomit"],
            ["Airway Collapse","collapse"],["Apnea","apnea"],["Pneumothorax","pneumo"],
            ["Tension Pneumo","tpneumo"],["Hemothorax","hemothorax"],["Decompress / Clear","ncd"]
        ];
    };
    case "wounds": {
        private _selPart = uiNamespace getVariable ["ACME_MC_woundPart","Body"];
        [_rX, _rY, _rW, 0.030, format ["Target region:  %1   (pick a region, then a wound type to apply)", _selPart], [1,0.9,0.5,1], _acc, _disp] call _mkLabel;
        private _cols = 6; private _bw = (_rW - (0.006*(_cols-1)))/_cols; private _bh = _rH/5.2;
        private _py1 = _rY + 0.032;
        { _x params ["_lbl","_key"];
          private _cx = _rX + (_forEachIndex * (_bw + 0.006));
          [_cx,_py1,_bw,_bh,_lbl,_key, { uiNamespace setVariable ["ACME_MC_woundPart", (_this select 0) getVariable ["mc_key","Body"]]; [87300,"wounds"] call ACME_fnc_megacodeMenu; }, (_selPart isEqualTo _key), _acc, _disp] call _mkBtn;
        } forEach [["Head","Head"],["Torso","Body"],["L Arm","LeftArm"],["R Arm","RightArm"],["L Leg","LeftLeg"],["R Leg","RightLeg"]];
        private _py2 = _py1 + _bh + 0.010;
        private _cols2 = 4; private _bw2 = (_rW - (0.006*(_cols2-1)))/_cols2;
        { _x params ["_lbl","_key"];
          private _cx = _rX + ((_forEachIndex % _cols2) * (_bw2 + 0.006));
          private _cyr = _py2 + (floor (_forEachIndex / _cols2) * (_bh + 0.006));
          [_cx,_cyr,_bw2,_bh,_lbl,_key, { [(_this select 0) getVariable ["mc_key","laceration"]] call ACME_fnc_megacodeAddWound; }, false, _acc, _disp] call _mkBtn;
        } forEach [
            ["Laceration","laceration"],["Gunshot","gunshot"],["Avulsion","avulsion"],["Amputation","amputation"],
            ["Burn","burn"],["Crush","crush"],["Velocity/Frag","velocity"],["Spawn Axilla","axilla"],
            ["Spawn Inguinal","inguinal"],["Clear All Wounds","clear"]
        ];
    };
    case "neuro": {
        private _col1 = _rX; private _col2 = _rX + _rW*0.52; private _cw = _rW*0.46;
        private _rowH = _rH/4.2;
        // the ICP slider drives a live cushing response, with the hr down and the bp up, and the GCS slider drives real
        // consciousness.
        [_col1, _rY, _cw, "ICP (mmHg)", "ICP", 0, 60, (_dummy getVariable ["ACME_MC_ICP",10]), _acc, _disp] call _mkSlider;
        [_col1, _rY + _rowH, _cw, "GCS", "GCS", 3, 15, (_dummy getVariable ["ACME_MC_GCS",15]), _acc, _disp] call _mkSlider;
        [_col1, _rY + (_rowH*2), _cw, 0.030, "ICP raises -> bradycardia + hypertension (Cushing).  GCS <9 -> unconscious.", [0.7,0.75,0.85,1], _acc, _disp] call _mkLabel;
        // buttons that each produce a real, live effect on the dummy. the pupil states were removed, because arma renders
        // no pupils and the monitor shows none, so they had no effect on anything the trainee sees.
        private _bh = _rowH*0.82; private _bw = _cw*0.96;
        private _unc = _dummy getVariable ["ACE_isUnconscious", false];
        private _feat = [
            ["Herniation (Cushing + coma)","herniation"],
            [(if (_unc) then {"Wake Up"} else {"Make Unconscious"}),"uncon"]
        ];
        { _x params ["_lbl","_key"];
          private _cyr = _rY + (_forEachIndex * (_bh + 0.008));
          [_col2,_cyr,_bw,_bh,_lbl,_key, { [(_this select 0) getVariable ["mc_key",""]] call ACME_fnc_megacodeSetFeature; }, false, _acc, _disp] call _mkBtn;
        } forEach _feat;
    };
    case "scenario": {
        // evolving clinical scenarios: each runs a timed, multi-stage deterioration that ends in, or passes through,
        // cardiac arrest for the trainee to work. they are one-shot triggers, and the header shows what is running.
        private _tgt   = uiNamespace getVariable ["ACME_MC_target", objNull];
        private _act   = _tgt getVariable ["ACME_MC_scenActive", false];
        private _nm    = _tgt getVariable ["ACME_MC_scenName", ""];
        private _hdr = if (_act && {_nm != ""}) then {
            format ["Running: %1", _nm]
        } else {
            "Pick a scenario."
        };
        [_rX, _rY, _rW, 0.030, _hdr, (if (_act) then {[0.78,0.62,1,1]} else {[1,0.9,0.5,1]}), _acc, _disp] call _mkLabel;

        private _scn = [
            ["ACS -> VF arrest",        "acs_vf"],         ["Tension pneumo -> PEA",   "tension_pea"],
            ["Hemorrhage -> PEA",       "hemorrhage_pea"], ["Hyperkalemia -> VF",      "hyperk_vf"],
            ["Rising ICP -> herniation","icp_herniation"], ["Hypoxia -> bradyasystole","hypoxia_asys"],
            ["Septic shock -> PEA",     "sepsis_pea"]
        ];
        private _cols = 4; private _bw = (_rW - (0.006*(_cols-1)))/_cols; private _bh = _rH/4.0;
        private _py1 = _rY + 0.036;
        { _x params ["_lbl","_key"];
          private _cx = _rX + ((_forEachIndex % _cols) * (_bw + 0.006));
          private _cyr = _py1 + (floor (_forEachIndex / _cols) * (_bh + 0.008));
          [_cx,_cyr,_bw,_bh,_lbl,_key, { [(_this select 0) getVariable ["mc_key",""]] call ACME_fnc_megacodeScenario; }, false, _acc, _disp] call _mkBtn;
        } forEach _scn;

        private _stopY = _py1 + (2 * (_bh + 0.008));
        private _stop = [_rX, _stopY, _rW*0.42, _bh, (if (_act) then {"STOP SCENARIO"} else {"(no scenario running)"}), "stop", { ["stop"] call ACME_fnc_megacodeScenario; }, _act, _acc, _disp] call _mkBtn;
        _stop ctrlSetBackgroundColor (if (_act) then {["danger", 1] call ACME_fnc_a11yColor} else {[0.16,0.10,0.10,1]});
        _stop ctrlEnable _act;
        _stop ctrlCommit 0;
    };
    case "log": {
        // the activity log of everything applied to the manikin this session, newest first.
        private _box = _disp ctrlCreate ["RscStructuredText", -1];
        _box ctrlSetPosition [_rX, _rY + 0.004, _rW, _rH - 0.008];
        _box ctrlSetBackgroundColor [0,0,0,0];
        private _log = uiNamespace getVariable ["ACME_MC_log", []];
        private _txt = if (_log isEqualTo []) then {
            "<t align='left' size='1.0' color='#6b7785'>No actions applied yet. Set a rhythm, airway, wound, or vital and it will be logged here.</t>"
        } else {
            private _s = "";
            { _x params [["_m",""],["_h","#cfe8ff"]]; _s = _s + format ["<t align='left' size='0.95' color='%1'>%2</t><br/>", _h, _m]; } forEach _log;
            _s
        };
        _box ctrlSetStructuredText parseText _txt;
        _acc pushBack _box;
    };
};
uiNamespace setVariable ["ACME_MC_contentCtrls", _acc];
