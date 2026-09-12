/* B78: carousel hover is presentation-only. Hover fades the syringe under the pointer to 100% opacity and
   preserves the selected syringe tooltip, but NEVER expands/collapses the carousel. Geometry changes only from
   explicit click/A-D navigation (or an explicit clicked administration/edit workflow). */
params [["_hover",false,[false]]];
if ((uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body") exitWith {};
if (uiNamespace getVariable ["ACME_SK_TagEditMode",false]) exitWith {};
uiNamespace setVariable ["ACME_SK_CarouselHover",_hover];
private _d = findDisplay 84000;
if (!isNull _d) then {[0.10] call ACME_fnc_skCarouselRender;};
if (uiNamespace getVariable ["ACME_SK_CarouselExpanded",false]) then {
    uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",diag_tickTime + (if (_hover) then {1.10} else {0.70})];
};
