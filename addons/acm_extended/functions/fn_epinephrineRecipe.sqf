/* Pure validation: exact 10 mL flush + 1 mL 0.1 mg/mL source after wasting 1 mL.
   Input slop is snapped to the labeled graduation before any inventory or dose mutation. */
params ["_med", "_cap", "_drugMl", "_salineMl"];
_med == "EpinephrineCardiac" && {abs (_cap - 10) < 0.001}
    && {abs (_drugMl - 1) <= 0.05} && {abs (_salineMl - 9) <= 0.05}
