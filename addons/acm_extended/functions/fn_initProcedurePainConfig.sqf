/*
 * Phase 22 subsystem initialization: IO, thoracostomy and chest-seal procedural pain/logging tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// B45 IO pain contract. Native ACM still owns insertion and access state; this additive owner-local handler
// guarantees the requested moderate insertion-pain floor even when native lidocaine suppression would reduce it.
// Any subsequent IO fluid flow is max-severity pain and schedules syncope about three seconds later.
ACME_ioInsertionMinPain = 0.35;
ACME_ioFluidPain = 1.0;
ACME_ioFluidSyncopeDelay = 3;
ACME_procLocalLidocaineThreshold = 0.5;
ACME_procKetamineAnalgesiaThreshold = 0.08;
ACME_thora_incisionPain = 0.70;
ACME_chestSealApplyLogCooldown = 30;
ACME_chestSealBurpLogCooldown = 10;
ACME_chestSealRemoveLogCooldown = 10;
