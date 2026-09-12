/* Phase 82: authoritative writer for medication request escrow.
 * The escrow remains supplier-local/public exactly as before; this function only centralizes publication.
 */
params ["_medic", "_escrow"];
if (isNull _medic) exitWith {};
_medic setVariable ["ACME_medicationEscrow", _escrow, true];
