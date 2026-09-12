/* B60: a newly prepared syringe starts untagged unless the provider explicitly selects a tag. */
uiNamespace setVariable ["ACME_SK_PendingTagColor", "none"];
uiNamespace setVariable ["ACME_SK_PendingTagText", ["","",""]];
private _d = findDisplay 84000;
if (!isNull _d) then {call ACME_fnc_skPendingTagRender;};
