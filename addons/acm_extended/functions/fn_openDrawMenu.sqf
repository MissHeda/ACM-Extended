/* B41: infusion prep uses a mode-local medication source.  Do not mutate ACM's global vial registry.
   The previous implementation temporarily replaced ACM_circulation_MedicationVialList and restored it on
   dialog close. Any interrupted/unload path could leak that temporary registry into the next normal Narc Box.
   ACME's Syringe_GetMedicationList/Syringe_UpdateMedicationList overrides already inspect the pending infusion
   context, so the global registry can remain the immutable full list for the entire session. */
call ACME_fnc_restoreMedicationList;

private _context = missionNamespace getVariable ["ACME_infusion_pendingContext", []];
if (_context isEqualTo []) exitWith {};

private _size = _context select 12;

// Open the same dialog the Narc Box uses rather than ACM's bare draw.  In infusion mode the row builder obtains
// ACME_infusion_allowedVials directly from ACME_infusion_pendingContext; nothing global is swapped here.
[_size, _context param [1, objNull], _context param [2, ""]] call ACME_fnc_skOpenDraw;
