// delete the runtime-built cooler slot-bay controls, meaning the frames, art, labels and hotspots. it is called
// before each refresh, so the bays are rebuilt cleanly for the current contents, and on dialog unload.
{
    if (!isNull _x) then { ctrlDelete _x; };
} forEach (uiNamespace getVariable ["ACME_CLR_SlotCtrls", []]);
uiNamespace setVariable ["ACME_CLR_SlotCtrls", []];
