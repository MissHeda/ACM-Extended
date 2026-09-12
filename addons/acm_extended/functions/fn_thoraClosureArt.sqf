/* Use one texture and anchor contract for the held and placed closure.
   A dressing is centered over the incision. Tube art keeps its existing tape anchor. */
params [["_tool", "seal", [""]], ["_side", "right", [""]]];
if (_tool == "seal") exitWith {
    ["\x\acm\addons\breathing\ui\chestseal_ca.paa", 0.18, [0.5, 0.5]]
};
[format ["\acm_extended\ui\items\chest_tube_%1_placed_ca.paa", ["left", "right"] select (_side == "left")],
 missionNamespace getVariable ["ACME_thora_tubeSize", 0.34],
 missionNamespace getVariable [["ACME_thora_tubeAnchorRight", "ACME_thora_tubeAnchorLeft"] select (_side == "left"), [0.32, 0.30]]]
