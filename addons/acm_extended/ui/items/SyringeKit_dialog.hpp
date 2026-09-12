// the custom syringe kit bench, idd 86300. the controls are given placeholder geometry here and fully positioned in
// ACME_fnc_syringeKitOnLoad, through safezone math, mirroring the roller-clamp dialog.
// the procedural fills, #(argb,8,8,3)color(1,1,1,1) tinted through ctrlSetTextColor, draw the barrel, fluid, plunger
// and rod, and the lists and buttons are populated and wired at runtime.
class ACME_SyringeKit_Dialog {
    idd = 86300;
    movingEnable = 0;
    enableSimulation = 1;
    onLoad = "call ACME_fnc_syringeKitOnLoad";
    onUnload = "private _h = uiNamespace getVariable ['ACME_SK_PFH', -1]; if (_h >= 0) then {[_h] call CBA_fnc_removePerFrameHandler;}; uiNamespace setVariable ['ACME_SK_PFH', -1]; uiNamespace setVariable ['ACME_SK_DLG', displayNull]; uiNamespace setVariable ['ACME_SK_InitDisplay', displayNull]; uiNamespace setVariable ['ACME_SK_Grab', false];";

    class ControlsBackground {
        class ACME_SK_Backdrop: RscText {
            idc = 86310;
            text = "";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.35)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 2.5)";
            w = "safeZoneW / 2.17";
            h = "safeZoneH / 1.25";
            colorBackground[] = {0,0,0,0.84};
            colorText[] = {1,1,1,1};
        };
        class ACME_SK_Title: RscText {
            idc = 86311;
            text = "Syringe Kit";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.35)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 2.5)";
            w = "safeZoneW / 2.17";
            h = "safeZoneH / 20";
            colorText[] = {1,1,1,1};
            colorBackground[] = {0,0,0,0};
            font = "RobotoCondensed";
            sizeEx = "safeZoneH / 30";
            style = 2;
            shadow = 0;
        };
        class ACME_SK_BarrelBG: RscPicture {
            idc = 86312;
            text = "#(argb,8,8,3)color(1,1,1,1)";
            colorText[] = {1,1,1,0.1};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 4)";
            w = "safeZoneW / 22";
            h = "safeZoneH / 3";
        };
    };

    class Controls {
        class ACME_SK_Fluid: RscPicture {
            idc = 86313;
            text = "#(argb,8,8,3)color(1,1,1,1)";
            colorText[] = {0.55,0.78,1,0.62};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 4)";
            w = "safeZoneW / 22";
            h = "safeZoneH / 8";
        };
        // the real in-game saline-flush syringe, drawn on top of the blue fluid rect so the fluid reads as liquid inside the
        // translucent glass barrel.
        // it is fully positioned in onload, and the fluid column and moving plunger line are aligned to the barrel glass
        // through ACME_SK_Geo.
        class ACME_SK_Syringe: RscPicture {
            idc = 86326;
            text = "\acm_extended\ui\items\salineFlush_ca.paa";
            colorText[] = {1,1,1,1};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 4)";
            w = "safeZoneW / 10";
            h = "safeZoneH / 3";
        };
        class ACME_SK_Plunger: RscPicture {
            idc = 86314;
            text = "#(argb,8,8,3)color(1,1,1,1)";
            colorText[] = {0.18,0.18,0.2,1};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2)";
            w = "safeZoneW / 22";
            h = "safeZoneH / 80";
        };
        class ACME_SK_Rod: RscPicture {
            idc = 86315;
            text = "#(argb,8,8,3)color(1,1,1,1)";
            colorText[] = {0.5,0.5,0.52,1};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2)";
            w = "safeZoneW / 90";
            h = "safeZoneH / 12";
        };
        class ACME_SK_Overlay: RscButton {
            idc = 86316;
            text = "";
            colorText[] = {1,1,1,0};
            colorDisabled[] = {1,1,1,0};
            colorBackground[] = {1,1,1,0.01};
            colorBackgroundDisabled[] = {1,1,1,0};
            colorBackgroundActive[] = {1,1,1,0.01};
            colorFocused[] = {1,1,1,0.01};
            colorBorder[] = {0,0,0,0};
            x = "safeZoneX + (safeZoneW / 2)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 4)";
            w = "safeZoneW / 22";
            h = "safeZoneH / 3";
            shadow = 0;
            font = "RobotoCondensed";
            sizeEx = "0";
            action = "";
            tooltip = "Click to grab the plunger, move the mouse to draw/expel, click again to set.";
        };
        class ACME_SK_SizesLabel: RscText {
            idc = 86319;
            text = "Syringe Size";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.6)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 3)";
            w = "safeZoneW / 7";
            h = "safeZoneH / 28";
            colorText[] = {0.8,0.8,0.8,1};
            colorBackground[] = {0,0,0,0};
            font = "RobotoCondensed";
            sizeEx = "safeZoneH / 44";
            style = 0;
        };
        class ACME_SK_SourcesLabel: ACME_SK_SizesLabel {
            idc = 86320;
            text = "Source";
        };
        class ACME_SK_SizesList: RscListBox {
            idc = 86317;
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.6)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 4)";
            w = "safeZoneW / 7";
            h = "safeZoneH / 4";
            rowHeight = "safeZoneH / 22";
            colorText[] = {1,1,1,1};
            colorSelect[] = {0,0,0,1};
            colorSelect2[] = {0,0,0,1};
            colorBackground[] = {0,0,0,0.25};
            colorSelectBackground[] = {0.7,0.7,0.7,1};
            colorSelectBackground2[] = {0.7,0.7,0.7,1};
            sizeEx = "safeZoneH / 40";
            class Items {};
        };
        class ACME_SK_SourcesList: ACME_SK_SizesList {
            idc = 86318;
            y = "safeZoneY + (safeZoneH / 2)";
            h = "safeZoneH / 6";
        };
        class ACME_SK_VolText: RscText {
            idc = 86321;
            text = "0.0 mL";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 30)";
            y = "safeZoneY + (safeZoneH / 2) - (safeZoneH / 3)";
            w = "safeZoneW / 8";
            h = "safeZoneH / 22";
            colorText[] = {1,1,1,1};
            colorBackground[] = {0,0,0,0};
            font = "RobotoCondensed";
            sizeEx = "safeZoneH / 28";
            style = 2;
            shadow = 0;
        };
        class ACME_SK_Info: RscText {
            idc = 86322;
            text = "";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.35)";
            y = "safeZoneY + (safeZoneH / 2) + (safeZoneH / 3.4)";
            w = "safeZoneW / 2.17";
            h = "safeZoneH / 22";
            colorText[] = {0.85,0.85,0.85,1};
            colorBackground[] = {0,0,0,0.4};
            font = "RobotoCondensed";
            sizeEx = "safeZoneH / 46";
            style = 2;
            shadow = 0;
        };
        class ACME_SK_Waste: RscButton {
            idc = 86323;
            text = "Waste";
            x = "safeZoneX + (safeZoneW / 2) - (safeZoneW / 4.35)";
            y = "safeZoneY + (safeZoneH / 2) + (safeZoneH / 2.8)";
            w = "safeZoneW / 8";
            h = "safeZoneH / 22";
            colorText[] = {1,1,1,1};
            colorDisabled[] = {1,1,1,0.25};
            colorBackground[] = {0,0,0,1};
            colorBackgroundDisabled[] = {0,0,0,0.35};
            colorBackgroundActive[] = {0.12,0.12,0.12,1};
            colorFocused[] = {0,0,0,1};
            colorBorder[] = {0,0,0,0};
            style = 2;
            shadow = 0;
            font = "RobotoCondensed";
            sizeEx = "safeZoneH / 46";
            action = "";
            tooltip = "Expel down to the plunger and lock that as the saline base.";
        };
        class ACME_SK_Draw: ACME_SK_Waste {
            idc = 86324;
            text = "Draw";
            tooltip = "Store the prepared push-dose pressor.";
        };
        class ACME_SK_Close: ACME_SK_Waste {
            idc = 86325;
            text = "Close";
            tooltip = "Close the syringe kit.";
        };
    };
};
