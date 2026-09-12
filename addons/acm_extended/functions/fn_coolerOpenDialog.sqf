// open the cooler manager for a given cooler class. close the inventory first so the dialog is not fighting it, then
// open next frame. the class being managed is stashed in uinamespace for the refresh, load and unload to read.
params ["_coolerClass"];
if ((_coolerClass find "ACME_BloodCooler_") != 0) exitWith {
};
uiNamespace setVariable ["ACME_CLR_Class", _coolerClass];
private _inv = findDisplay 602;
if (!isNull _inv) then { _inv closeDisplay 2; };
[{
    params ["_coolerClass"];
    // re-assert the class right before creating the dialog, which guards against anything clearing it in between.
    uiNamespace setVariable ["ACME_CLR_Class", _coolerClass];
    private _ok = createDialog "ACME_CoolerManager_Dialog";
    // belt and suspenders: grab the display by idd and drive the refresh ourselves next frame, independent of the
    // onload timing of the dialog, in case the call of onload resolved before the function or the controls were
    // ready.
    [{
        private _d = findDisplay 87400;
        if (!isNull _d) then {
            uiNamespace setVariable ["ACME_CLR_DLG", _d];
            call ACME_fnc_coolerRefresh;
        };
    }, []] call CBA_fnc_execNextFrame;
}, [_coolerClass]] call CBA_fnc_execNextFrame;
