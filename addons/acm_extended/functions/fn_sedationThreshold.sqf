/* All maintenance consumers share this setting. No startup assignment overwrites the CBA value.
   Clamp hysteresis below induction even if an old/custom preset crosses its sliders. */
private _induce = (missionNamespace getVariable ["ACME_ket_induceThreshold", 7]) max 0.1;
((missionNamespace getVariable ["ACME_ket_maintainThreshold", 1.2]) / _induce) max 0.1 min 0.95
