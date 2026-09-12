// inflating the cuff.
// ["show"] call ACME_fnc_laryngoCuff means the syringe was taken from the tray.
// ["grab"] call ACME_fnc_laryngoCuff means the left mouse was pressed while it is on the pilot balloon.
// ["release"] call ACME_fnc_laryngoCuff means the left mouse was released.
// ["tick"] call ACME_fnc_laryngoCuff runs per frame, from the tick.
// this is a hold rather than a drag. the syringe follows the cursor, magnetizes lightly onto the pilot balloon, and
// clicking there anchors it and starts the draw. you have to hold for the whole run of the sound: let go early and
// the air comes back out and you start again. that is what makes it an act rather than a click.
// the sound is a source rather than a fired one-shot, because a fired sound cannot be stopped in this engine and the
// audio has to cut the instant the button comes up.
params [["_mode", "tick"]];
disableSerialization;
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (isNull _dlg) exitWith {};
private _cBack = _dlg displayCtrl 87814;
private _cPlunger = _dlg displayCtrl 87817;
private _cBarrel = _dlg displayCtrl 87818;

private _stopSfx = {
    private _med = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
    private _src = _med getVariable ["ACME_laryngo_cuffSfx", objNull];
    if (!isNull _src) then { deleteVehicle _src; };
    _med setVariable ["ACME_laryngo_cuffSfx", objNull];
};

switch (_mode) do {
    case "show": {
        uiNamespace setVariable ["ACME_laryngo_cuffAmt", 0];
        uiNamespace setVariable ["ACME_laryngo_cuffGrab", false];
        uiNamespace setVariable ["ACME_laryngo_cuffSnap", false];
        call _stopSfx;
    };

    case "grab": {
        // B39: cuff work is available as soon as any portion of the tube is in the mouth/airway.
        if ((uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0]) <= 0.001) exitWith {
            ["Advance the ET tube before inflating the cuff.", 1.5] call ace_common_fnc_displayTextStructured;
        };
        // it only takes on the pilot balloon. anywhere else and there is nothing to inflate.
        if !(uiNamespace getVariable ["ACME_laryngo_cuffSnap", false]) exitWith {
            ["Put the syringe on the pilot balloon first.", 1.5] call ace_common_fnc_displayTextStructured;
        };
        uiNamespace setVariable ["ACME_laryngo_cuffGrab", true];
        uiNamespace setVariable ["ACME_laryngo_cuffAmt", 0];
        uiNamespace setVariable ["ACME_laryngo_cuffStart", diag_tickTime];
        call _stopSfx;
        private _med = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
        private _src = createSoundSource ["ACME_SyringeDraw_SoundSource", getPosATL _med, [], 0];
        if (!isNull _src) then { _src attachTo [_med, [0, 0.1, 0.2]]; };
        _med setVariable ["ACME_laryngo_cuffSfx", _src];
    };

    case "release": {
        if (uiNamespace getVariable ["ACME_laryngo_cuffGrab", false]) then {
            uiNamespace setVariable ["ACME_laryngo_cuffGrab", false];
            call _stopSfx;
            if ((uiNamespace getVariable ["ACME_laryngo_cuffAmt", 0]) < 1) then {
                uiNamespace setVariable ["ACME_laryngo_cuffAmt", 0];
                ["Let go too early. The air came straight back out.", 2] call ace_common_fnc_displayTextStructured;
            };
        };
    };

    case "tick": {
        (uiNamespace getVariable ["ACME_laryngo_frame", [0,0,0.2,0.2]]) params ["_fx","_fy","_fw","_fh"];
        (uiNamespace getVariable ["ACME_laryngo_cur", [_fx + _fw/2, _fy + _fh/2]]) params ["_cx","_cy"];
        // B39: the pilot balloon sits on the free/proximal side of the ETT, not in the middle of the tube.
        // Resolve it from the tube sprite's current placement so the target follows a seated or repositioned tube.
        private _tubeCtrl = _dlg displayCtrl 87907;
        private _tubePos = if (!isNull _tubeCtrl) then {ctrlPosition _tubeCtrl} else {[_fx,_fy,_fw,_fh]};
        _tubePos params ["_tx","_ty","_tw","_th"];
        (missionNamespace getVariable ["ACME_laryngo_cuffPilotUV", [0.548, 0.455]]) params ["_cpU","_cpV"];
        private _tgX = _tx + (_cpU * _tw);
        private _tgY = _ty + (_cpV * _th);
        // The replacement 10 mL barrel canvas is square. Anchor the tool at the actual distal Luer tip,
        // measured from the supplied 1024x1024 source at approximately x=512, y=379.
        (missionNamespace getVariable ["ACME_laryngo_syrTipUV", [0.50, 0.370]]) params ["_stU","_stV"];
        // smaller. at 0.55 of the view the syringe was over half the screen, so what read as being on the balloon was a
        // huge body sprawled across the head with the tip somewhere under it.
private _sc = missionNamespace getVariable ["ACME_laryngo_syrScale", 0.28];
        private _sw = _fw * _sc;
        private _sh = _fh * _sc;

        private _grab = uiNamespace getVariable ["ACME_laryngo_cuffGrab", false];

        private _pX = _cx; private _pY = _cy;
        if (_grab) then {
            // anchored: it does not move while you are holding it, whatever the mouse does.
            _pX = _tgX; _pY = _tgY;
        } else {
            // a light magnetization onto the balloon, the same feel as every other tool here.
            private _mR = _fh * (missionNamespace getVariable ["ACME_laryngo_cuffMagnet", 0.17]);
            private _oX = _cx - _tgX; private _oY = _cy - _tgY;
            private _oD = sqrt (((_oX*_oX) + (_oY*_oY)) max 0);
            private _mg = if (_oD <= _mR && {_mR > 1e-5}) then { (_oD / _mR) ^ 1.5 } else { 1 };
            _pX = _tgX + (_oX * _mg); _pY = _tgY + (_oY * _mg);
            // the tip is what has to be on the balloon rather than the cursor. the test used the raw pointer, so with the
            // magnet pulling the sprite one way and the pointer sitting somewhere else, the acceptance and the visible tip
            // could disagree. it is the tip position that is judged now, which is the thing the medic can actually see
            // touching the valve.
            // the acceptance is the marked square rather than a circle, so it matches the reference exactly.
            (missionNamespace getVariable ["ACME_laryngo_cuffBoxUV", [0.15, 0.19]]) params ["_cbW","_cbH"];
            private _dx = abs (_pX - _tgX);
            private _dy = abs (_pY - _tgY);
            uiNamespace setVariable ["ACME_laryngo_cuffSnap",
                (_dx <= ((_cbW * _fw) / 2)) && {_dy <= ((_cbH * _fh) / 2)}];
        };
        private _sx = _pX - (_stU * _sw);
        private _sy = _pY - (_stV * _sh);
        private _alpha = if (_grab || {uiNamespace getVariable ["ACME_laryngo_cuffSnap", false]}) then {1} else {0.55};
        _cBack ctrlSetPosition [_sx, _sy, _sw, _sh];
        _cBarrel ctrlSetPosition [_sx, _sy, _sw, _sh];
        // B52: the air syringe starts pulled back to 8 mL, not a completely full 10 mL barrel. The distal Luer
        // remains the fixed anchor while the plunger travels from the 8 mL mark to empty in exactly cuffRunTime.
        private _amtVis = uiNamespace getVariable ["ACME_laryngo_cuffAmt", 0];
        private _startMl = (missionNamespace getVariable ["ACME_laryngo_cuffStartMl", 8.0]) max 0 min 10;
        private _startFrac = _startMl / 10;
        private _plTravel = _sh * (missionNamespace getVariable ["ACME_laryngo_cuffPlungerTravel", 0.105]);
        _cPlunger ctrlSetPosition [_sx, _sy + (_plTravel * _startFrac * (1 - _amtVis)), _sw, _sh];
        {_x ctrlCommit 0; _x ctrlSetTextColor [1,1,1,_alpha];} forEach [_cBack,_cPlunger,_cBarrel];

        if (!_grab) exitWith {};
        private _run = missionNamespace getVariable ["ACME_laryngo_cuffRunTime", 1.0];
        private _amt = ((diag_tickTime - (uiNamespace getVariable ["ACME_laryngo_cuffStart", diag_tickTime])) / (_run max 0.1)) min 1;
        uiNamespace setVariable ["ACME_laryngo_cuffAmt", _amt];
        (_dlg displayCtrl 87810) ctrlSetText format ["Inflating the cuff. Keep holding. %1%2", round (_amt * 100), "%"];
        if (_amt >= 1) then {
            uiNamespace setVariable ["ACME_laryngo_cuffGrab", false];
            call _stopSfx;
            [] call ACME_fnc_laryngoCuffDone;
        };
    };
};
