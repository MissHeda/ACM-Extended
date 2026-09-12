// thread the catheter off the needle with the mouse wheel.
// call it as [_dir] call ACME_fnc_ivMinigameScroll, where _dir is 1 for up and -1 for down.
// it only does anything once the needle is fully in and flashback is up. one notch is one frame.
// frames 07 to 11 are the catheter sliding forward off the needle, in twenty percent steps.
params [["_dir", 0]];
if (_dir == 0) exitWith { false };
if ((uiNamespace getVariable ["ACME_IV_InsStage", ""]) != "thread") exitWith { false };

private _f = uiNamespace getVariable ["ACME_IV_InsFrame", 6];
// scrolling back withdraws the catheter, but never past the seated needle.
_f = (_f + _dir) max 6 min 11;
if (_f == (uiNamespace getVariable ["ACME_IV_InsFrame", 6])) exitWith { true };
uiNamespace setVariable ["ACME_IV_InsFrame", _f];

private _cath = uiNamespace getVariable ["ACME_IV_CathCtrl", controlNull];
if (!isNull _cath) then {
    [_cath, ([(uiNamespace getVariable ["ACME_IV_InsGauge", 16]),
                        (uiNamespace getVariable ["ACME_IV_InsSuffix", ""]), _f] call ACME_fnc_ivCathTex)] call ACME_fnc_ivCathSetFrame;
};

private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (!isNull _dlg) then {
    if (_f >= 11) then {
        (_dlg displayCtrl 86503) ctrlSetText "Catheter is hubbed. Right click to separate the needle from it.";
    } else {
        (_dlg displayCtrl 86503) ctrlSetText format ["Threading. %1 percent.", (_f - 6) * 20];
    };
};
true
