// set each tray slot icon to the side-appropriate texture for the current side. it is called on open and on flip, so
// the tray always shows the correct left and right tool art.
// it preserves the current tint of each icon, such as the black picked-up silhouette, because we only change the
// texture here.
disableSerialization;
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
{
    private _tool = _x getVariable ["thoraTool", ""];
    private _ic = _x getVariable ["thoraIcon", controlNull];
    if (!isNull _ic) then {
        private _tex = switch (_tool) do {
            case "chlorhexidine": { format ["\acm_extended\ui\items\chlorhexidine_%1_ca.paa", _side] };
            case "scalpel":       { "\x\acm\addons\airway\ui\surgical_airway\inv_scalpel.paa" };
            case "finger":        { format ["\acm_extended\ui\items\thoracostomy_finger_%1_ca.paa", _side] };
            // the slot shows whatever it will actually place, so the tray never offers a tool that does nothing
            // when it is clicked. the seal art is ACM's own, the same one the chest seal screen draws.
            case "tube": {
                if (uiNamespace getVariable ["ACME_Thora_SealMode", false]) then {
                    "\x\acm\addons\breathing\ui\chestseal_ca.paa"
                } else {
                    format ["\acm_extended\ui\items\chest_tube_%1_placed_ca.paa", ["left", "right"] select (_side == "left")]
                };
            };
            default { "" };
        };
        if (_tex != "") then { _ic ctrlSetText _tex; };
    };
} forEach (uiNamespace getVariable ["ACME_Thora_SlotBGs", []]);
