/* B48: restore ACM's real runtime vial registry. ACM_MEDICATION_VIALS is a compile-time macro that expands
   to ACM_circulation_MedicationVialList; there is no literal runtime registry named ACM_MEDICATION_VIALS. */
private _full = missionNamespace getVariable ["ACME_medicationVialRegistryFull", []];
if !(_full isEqualTo []) then {
    [["medicationVialList", +_full]] call ACM_circulation_fnc_setLocalUiState;
};
ACME_infusion_savedMedicationVials = nil;
