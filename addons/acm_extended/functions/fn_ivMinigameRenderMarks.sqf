// render the persistent iv marks, meaning the placed hubs, removed sites and missed holes, stored on the patient
// that belong to the current limb and view. it deletes any previously-rendered mark sprites first. it is called
// on init and on flip, so the sites stay put when you re-open or flip the limb.
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg) exitWith {};
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", []];
if (_rect isEqualTo []) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];
private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
private _view = uiNamespace getVariable ["ACME_IV_View", ""];

{ if (!isNull _x) then { ctrlDelete _x; }; } forEach (uiNamespace getVariable ["ACME_IV_MarkCtrls", []]);
private _ctrls = [];

private _marks = if (isNull _patient) then { [] } else { _patient getVariable ["ACME_IV_Marks", []] };
private _anchors = uiNamespace getVariable ["ACME_IV_FrameAnchors", createHashMap];
private _fades = [];
private _hubCtrls = [];
{
    _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""], ["_mframe", ""], ["_mgauge", 0], ["_mmiss", -1], ["_mscale", 1]];
    if (_mbp == _bp && {_mview == _view}) then {
        if (_mkind == "hub") then {
            private _c = _dlg ctrlCreate ["ACME_IV_HubMark", -1];
            // every iv, the ej included, builds its hub path from the frame now. the _mtex branch only fires for any legacy
            // iv_ej marker still stored on a patient from an older build, whose anchor sits higher.
            // the seated hub is frame 14 of the supercath set, being the catheter with the needle gone. a mark saved by
            // an older build has gauge 0, so it draws in 16g.
            private _mg = if (_mgauge in [14, 16, 18, 20]) then { _mgauge } else { 16 };
            if (_mtex != "") then { _c ctrlSetText _mtex; } else { _c ctrlSetText ([_mg, _mframe, 14] call ACME_fnc_ivCathTex); };
            // the hub frame shares the insertion plane with every other frame, so it uses the one anchor.
            private _anc = _anchors getOrDefault [_mframe, [0.49166, 0.44434]];
            if (_mtex find "iv_ej_left" >= 0) then { _anc = [0.516, 0.176]; };
            if (_mtex find "iv_ej_right" >= 0) then { _anc = [0.484, 0.176]; };
            _anc params ["_tipFx", "_tipFy"];
            // the hub and the line draw at the same scale as the catheter that placed them, or the seated art would not
            // match the one the medic just pushed in. a legacy body-diagram marker keeps its own full size.
            private _hs = uiNamespace getVariable ["ACME_IV_CathScale", 0.62];
            if (_mtex find "iv_ej_left" >= 0 || {_mtex find "iv_ej_right" >= 0}) then { _hs = 1; };
            // keep the hub on the exact same frame anchor as the base and inserted catheter art. the texture set is authored to
            // transition in place, so do not apply additional per-stage offsets here.
            [_c, _bx + _bw * _mu, _by + _bh * _mv, _mframe, _x param [13,0], _hs, _anc] call ACME_fnc_ivCathPose;
            _c ctrlShow true;
            _ctrls pushBack _c;
            // a hub keeps its own index, paired with the mark it belongs to.
            // ACME_IV_MarkCtrls is a flat list with more than one control per mark and only for the marks on this
            // view, so indexing it by mark number gives the wrong control. the pull needs the exact sprite for the
            // hub it took hold of, which is what this pairing provides.
            _hubCtrls pushBack [_forEachIndex, _c];
        } else {
            // the miss-site bruise first, under the hole, gauge-correlated, scaled to fit and faded in.
            if (_mkind == "miss" && {_mgauge > 0}) then {
                private _b = _dlg ctrlCreate ["ACME_IV_Bruise", -1];
                // THE BRUISE ART EXISTS FOR 14g, 16g AND 18g ONLY. there is no bruise_20g_ca.paa in the tree,
                // and a texture path to a file that is not packed reports Picture not found rather than falling
                // back to anything. a 20g therefore borrows the 18g bruise, which is the nearest bore. drop
                // ui/iv/bruise_20g_ca.paa in and delete the remap line.
                private _bruiseG = _mgauge;
                if (_bruiseG == 20) then { _bruiseG = 18; };
                _b ctrlSetText (if (_mbp == "ej") then {"\acm_extended\ui\iv\bruise_ej_ca.paa"} else {format ["\acm_extended\ui\iv\bruise_%1g_ca.paa", _bruiseG]});
                private _brW = _mscale * _bw; private _brH = _mscale * _bh;
                // MEASURED, not typed. the painted bruise sits in the middle of a mostly empty canvas, and this is
                // where its content actually is. decoded from the 128x128 uncompressed mipmap of each file and
                // read at texel accuracy, the center is 0.500 by 0.500 in every one of the five bruise textures.
                // it was 0.492 on the v axis, which put every bruise a little high of the needle. small, and it is
                // the same class of error as the hand-typed body map table.
                // note for anyone changing the art: the content is only about 6.5 percent of the canvas at alpha
                // above 8, so the control has to be roughly fifteen times the intended bruise size for the mark to
                // read correctly, and any anchor error is magnified by the same factor.
                private _aX = 0.500; private _aY = 0.500;
                _b ctrlSetPosition [_bx + (_bw * _mu) - (_brW * _aX), _by + (_bh * _mv) - (_brH * _aY), _brW, _brH];
                // a bruise never reaches full opacity. at alpha 1 the painted mark reads as a solid blob stuck on
                // the skin rather than something under it, and it buries the puncture hole drawn on top of it.
                private _cap = (missionNamespace getVariable ["ACME_iv_bruiseMaxAlpha", 0.90]);
                if (!(_cap isEqualType 0) || {!finite _cap}) then { _cap = 0.90 };
                _cap = (_cap max 0.05) min 1;
                // A BRUISE HAS A LIFE OF ABOUT TWENTY MINUTES.
                // it darkens over the first 15 s as blood tracks into the tissue, holds at the cap, then fades
                // out over the last stretch as it resolves. a puncture HOLE has no life and stays for the body.
                // the clock is CBA_missionTime, written by fn_ivInfiltrated, so the age is the same on every
                // machine and a bruise does not read as older on a client that has been running longer.
                private _al = _cap;
                if (_mmiss >= 0) then {
                    private _e = CBA_missionTime - _mmiss;
                    private _life = missionNamespace getVariable ["ACME_iv_bruiseLifeSec", 1200];
                    private _out  = missionNamespace getVariable ["ACME_iv_bruiseFadeOutSec", 300];
                    _al = switch (true) do {
                        case (_e < 0):                { _cap };  // a stamp from the future, so treat it as fresh.
                        case (_e < 15):               { (_e / 15) * _cap };
                        case (_e < (_life - _out)):   { _cap };
                        case (_e < _life):            { _cap * (((_life - _e) / (_out max 1)) max 0) };
                        default                       { 0 };
                    };
                };
                _b ctrlSetTextColor [1, 1, 1, _al];
                _b ctrlCommit 0;
                // the same both-ways test the per frame driver in fn_ivMinigameTick uses, and it has to be the
                // same or the two disagree the moment one of them runs.
                // it was a hide placed ABOVE an unconditional show, so it did nothing at all here and the resolved
                // bruise of a casualty who had been carrying one for twenty minutes reappeared on every rebuild.
                _b ctrlShow (_al > 0.004);
                _ctrls pushBack _b;
                _fades pushBack [_b, _mmiss];
            };
            // the puncture hole on top, but only where something actually came back out.
            // a seated hub leaves no hole, because the catheter is still sitting in it. the mark carries a hole
            // texture only for a pulled line. without this guard the control fell back to its config default,
            // hole1, and stamped a puncture beside every infiltration bruise.
            if (_mtex != "") then {
                private _c = _dlg ctrlCreate ["ACME_IV_Hole", -1];
                _c ctrlSetText _mtex;
                // the hole is the size of the bore that made it.
                // it used to be one size for every gauge, so a 14g and an 18g left an identical dot. they do not. the
                // outer diameters are 2.11 mm for 14g, 1.65 for 16g, 1.27 for 18g and 0.91 for 20g, so a 14g is a bit
                // over two and a half times the width of a 20g and it is plainly visible when it comes out.
                // the multiplier is the true diameter ratio against 18g, so the marks are in proportion to each other
                // rather than to a guess, and the base is a little larger than before because the old dot was too
                // small to read at all on the arm views.
                private _bore = switch (_mgauge) do {
                    case 14: { 1.66 };
                    case 16: { 1.30 };
                    case 18: { 1.00 };
                    case 20: { 0.72 };
                    default { 1.00 };
                };
                private _holeFrac = (if (_mbp in ["leftleg", "rightleg"]) then { 0.0090 } else { 0.0045 }) * _bore;
                private _r = _bh * _holeFrac;  // a very small puncture mark, at 2x on the legs.
                _c ctrlSetPosition [_bx + (_bw * _mu) - (_r / 2), _by + (_bh * _mv) - (_r / 2) / _af, _r, _r / _af];
                _c ctrlCommit 0;
                _c ctrlShow true;
                _ctrls pushBack _c;
            };
        };
    };
} forEach _marks;
{ [_x] call ACME_fnc_ivMinigameHookCtrl; } forEach _ctrls;
uiNamespace setVariable ["ACME_IV_MarkCtrls", _ctrls];
uiNamespace setVariable ["ACME_IV_HubCtrls", _hubCtrls];
uiNamespace setVariable ["ACME_IV_BruiseFades", _fades];
