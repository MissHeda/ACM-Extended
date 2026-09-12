// on the player opening their inventory: wire a double-click on the container and cargo lists, so double-clicking a
// blood cooler opens the cooler manager.
// coolers are ACE_ItemCore items rather than backpacks, so in most inventory rows the lbdata carries the classname.
// but depending on the list refresh of ACE, medical items can come through with an empty lbdata and only an
// lbpicture. to be robust we resolve the cooler class from either the lbdata, a direct classname match, or the
// lbpicture, reverse-mapped from CfgWeapons >> picture.
// the reverse map is rebuilt inside the handler on each click. the previous version passed it as a third
// ctrlAddEventHandler arg, and ctrlAddEventHandler does not forward extra registration args to the handler, which
// only gets [control, selindex], so that lookup was always nil and nothing opened.
params ["_unit"];
if (_unit isNotEqualTo ACE_player) exitWith {};
[{
    private _dlg = findDisplay 602;
    if (isNull _dlg) exitWith {};

    {
        private _ctrl = _dlg displayCtrl _x;
        if (!isNull _ctrl && {isNil {_ctrl getVariable "ACME_clrHook"}}) then {
            _ctrl setVariable ["ACME_clrHook", true];
            _ctrl ctrlAddEventHandler ["LBDblClick", {
                params ["_c", "_idx"];
                private _coolers = ["ACME_BloodCooler_CSWB1U", "ACME_BloodCooler_CSWB2U", "ACME_BloodCooler_CSWB4U"];
                // 1. the direct classname from the lbdata.
                private _data = _c lbData _idx;
                private _class = "";
                if (_data != "" && {_data in _coolers}) then { _class = _data; };
                // 2. fall back to a picture-path reverse match.
                if (_class == "") then {
                    private _pic = toLowerANSI (_c lbPicture _idx);
                    if (_pic != "") then {
                        {
                            if (toLowerANSI (getText (configFile >> "CfgWeapons" >> _x >> "picture")) == _pic) exitWith { _class = _x; };
                        } forEach _coolers;
                    };
                };
                if (_class != "") then {
                    [_class] call ACME_fnc_coolerOpenDialog;
                };
            }];
        };
    } forEach [632, 633, 638, 619];
}, []] call CBA_fnc_execNextFrame;
