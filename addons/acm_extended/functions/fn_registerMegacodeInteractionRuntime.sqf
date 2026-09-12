// megacode kelly. the control-panel interaction lives on the olive laptop, not the manikin. it registers on the
// laptop class on every machine, because postinit runs everywhere, jip included. the condition gates it to a
// laptop tagged as a megacode station, so an ordinary laptop is unaffected.
if (hasInterface || isServer) then {
    if (!isNil "ace_interact_menu_fnc_createAction") then {
        private _act = [
            "ACME_MegacodeControl",
            "Megacode Control Panel",
            "\a3\ui_f\data\IGUI\Cfg\Actions\heal_ca.paa",
            { [(_target getVariable ["ACME_megacodeDummy", objNull]), _player] call ACME_fnc_megacodeOpenPanel },
            { _target getVariable ["ACME_isMegacodeLaptop", false] }
        ] call ace_interact_menu_fnc_createAction;
        ["Land_Laptop_03_olive_F", 0, ["ACE_MainActions"], _act] call ace_interact_menu_fnc_addActionToClass;

        private _actCable = [
            "ACME_MegacodeTuneCable",
            "Tune Cable",
            "\a3\ui_f\data\IGUI\Cfg\Actions\heal_ca.paa",
            { [_target] call ACME_fnc_megacodeCableTunerOpen },
            { (missionNamespace getVariable ["ACME_debug_enabled", false]) && {_target getVariable ["ACME_isMegacodeLaptop", false]} }
        ] call ace_interact_menu_fnc_createAction;
        ["Land_Laptop_03_olive_F", 0, ["ACE_MainActions"], _actCable] call ace_interact_menu_fnc_addActionToClass;
    };
};
