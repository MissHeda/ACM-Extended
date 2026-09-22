# Historical backlog, batch 5: medication catalog and selector consistency

## Scope and provenance

Starting commit: `156adfb6c0486af0cd2861062e9d40c6574bd030`, complete source tree `56fa9ea33dca871e1e487689a542dabd9d411757`.
The connected GitHub main reference and commit tree were checked. A complete local checkout reconstructed from the pinned source/assets and the published batch changes matched that tree before editing. Baseline tests ran in a separate unchanged worktree.

Only **three runtime lines in three files** change: `fn_initMedicationRegistry.sqf`, `fn_restoreMedicationList.sqf`, and `fn_vialHolder.sqf`. Each adds the missing outer array around an existing call to `ACM_circulation_fnc_setLocalUiState`. The native writer, renderer, row builder, lease logic, inventory consumption and all medication/configuration values are unchanged. Earlier lifecycle, pulse, vial, chest and obtundation fixes are preserved. No assets or files are deleted.

## Confirmed failure and minimal correction

The native UI writer accepts one argument: an array of field/value pairs. Three callers instead supplied a single field/value pair as that argument. The writer iterated its contents instead of a list of changes and did not apply the intended field update.

1. **Initialization:** the native medication-vial catalog was not replaced with the finalized catalog and canonical cardiac-epinephrine presentation alias. The snapshot was still populated separately, which could obscure the disagreement.
2. **Restoration:** restoring a damaged/emptied live catalog from the saved full catalog did not actually update the native catalog. The row builder's independent snapshot/config fallback could hide this failed repair.
3. **Unavailable inventory:** the vial resolver correctly returned the provider after a patient/vehicle source became unavailable, but the native selector was not reset to Self. This incorporates the previously delivered but unpublished one-line vial-selector follow-up against the current source, rather than assuming it had already reached main.

The correction fixes the three callers, not the writer's API. It adds no special-case state exceptions, new timing, polling, inventory transport, or UI behavior. A reachable shared inventory still waits for its existing owner acknowledgment; dead-patient sources remain valid. An empty saved catalog still does not overwrite a valid live catalog. Snapshot/live-list copies remain independent.

The tests execute the actual caller and native writer together. On unchanged source, the same 43 new cases produce **8 failures and 35 passes**; after the corrections all **43 pass**. Five failing cases expose catalog initialization/restoration and three expose selector normalization. Positive controls include an already-correct catalog, empty-snapshot preservation and pending/acknowledged shared sources. No mock assumes the malformed write succeeded.

## Historical backlog progress

Fifteen original failed identities now pass: **H048, H141, H142, H143, H147, H150, H151, H152, H153, H154, H163, H164, H173, H174 and H187**.

All fifteen belong to the original unresolved source-contract subset, reducing it from **216 to 201**. Across the original 448 failed outcomes, **223 now pass and 225 remain failing**. The original seven collection and five setup error identities remain separately tracked as resolved. This is not a clearance of the remaining backlog.

The historical expectations now follow the current source, not retired intermediate renderers:

- The class catalog, actual selected-holder item counts and open-vial ledger determine row membership. Tests cover absent stock, positive partial vials after physical consumption, duplicate/malformed catalog entries, startup fallback, ampules, foreign medication suffixes, and vehicle versus provider inventory.
- Native selector rows and their metadata are synchronized before visible rows are bound. Valid native labels are retained; metadata is joined by medication key rather than a row index. Missing backing entries and blank labels/icons use the existing fallbacks. Duplicate native medication entries do not duplicate visible rows.
- Selection survives a reordered list by medication key. An unchanged refresh does not repeatedly clear/rebuild the backing selector, and the backing list remains hidden. Tests check the current stock-preview call's holder, reserved volume and exact physical class.
- Cardiac epinephrine's legacy/Extended stock aliases yield one canonical presentation row. Infusion filtering honors the existing medication/vial/extra lists without replacing the global catalog. Invalid source resolution does not consume inventory.

Some original method names mention a retired rule such as not reading native listbox labels. Those names are retained for ledger identity, with explicit comments documenting the current B51+ native-label/metadata-by-key contract. The renderer itself is not rewritten to satisfy an older assertion. No other animation/layout expectations are removed or waived.

## Verification

| Broad historical addon suite | Before | After |
| --- | ---: | ---: |
| Failing outcomes | 261 | 246 |
| Passing tests | 2,828 | 2,886 |
| Passing subtests | 5,518 | 5,518 |
| Collection/setup errors | 0 | 0 |
| Skips | 4 | 4 |

Individual-outcome comparison: **15 previous failures now pass, no newly failing identities, and no comparable previously passing outcomes regress**. Both broad-suite commands return exit code 1. The same four skips remain; no xfail marking, outcome manipulation or new skip filters are added.

The focused preservation/lifecycle/clinical suite passes **849 tests and 400 subtests**, with no failures, errors or skips. It retains the previous 791-case focused set and adds 43 new cases plus the fifteen historical identities. The 43 new cases comprise 41 SQF execution cases and two source-order/delegation checks. Full-project `hemtt check` returns **0**, retaining its seven existing non-blocking style suggestions.

The complete-tree check confines runtime edits to the three one-line calls and retains unrelated source/assets. The remaining 201 original source-contract identities remain in `historical-backlog-remaining-20260922.txt`; the evidence archive retains the complete 460-outcome history and before/after raw results.

## Execution boundaries and release checks

Toolchain: HEMTT 1.22.0, SQF-VM v2026.04.03-ed9f5f5, pytest 9.0.2. Config/catalog, inventory queries, object identities, native listbox operations and network acknowledgment are explicit fixtures. Native writer parameter parsing, row membership/normalization, identity joins and selection logic execute from the actual checked-out source. Unsupported VM continue maps to a named exit inside only its own loop iteration; real maps retain keys/set/get with a default-read equivalent. The existing native string-suffix selection uses an explicit end length in the VM adapter.

Nested-array alphabetical ordering is **not certified** by this VM: a minimal observed input remains unordered. No production sort change or substitute Python sorter was added. The unchanged native sort delegation is checked as a source invariant, while execution checks verify membership, full identities and repeated-refresh consistency. Config fixtures do not validate the game's actual inheritance, localization or every foreign addon. Listbox stand-ins do not prove rendered geometry or live UI-event timing.

No Arma client or dedicated server ran. A gameplay rebuild is required for the three runtime edits. Live checks should open Narc Box/Prep Infusion with Self, patient and vehicle inventory, remove or leave a selected source, verify that fallback also selects Self, and confirm that a reachable shared source still waits for acknowledgment. Check partial vials, canonical epinephrine rows and retained selection after stock changes. No medication dose, concentration, kinetics, threshold, animation, layout or inventory-consumption rule was retuned.

Keep the old local stash as a backup. Do not apply the earlier standalone selector patch or superseded installer scripts over this update; its correction is included here.

## Independent clean-checkout verification

GitHub Actions run **35796676167**, job **106977454433**, independently verified candidate **f0a4e89eb45bef7200316bf35bb91074a785d274**, parent **156adfb6c0486af0cd2861062e9d40c6574bd030**, and complete source tree **d56e0df51f8697587f45f9ec233bd9395705fd3c**. The reviewed patch SHA256 is **99db1acbb35305c5761f60a9fefd4b0ed4311bfc1998c7dedb1ec79177c41333**. The transferred payload and resulting tree matched their original expected hashes; no source was altered to satisfy the independent run.

The focused run passed **849 tests plus 400 subtests**, with no failures, errors or skips. Full-project HEMTT returned **0**. The two complete broad-suite runs reproduced the table above: **15 existing failed identities now pass, no newly failing identities, no comparable passing-outcome regressions, no collection/setup errors, and four unchanged skips**. Both broad runs still returned **1**; successful audit validation is not a clean historical-suite result.

The independent unchanged-source control copied only the two new regression modules onto the old checkout and produced **8 failed and 35 passed**. The same **43 cases all passed** on the candidate. Runtime differences are exactly **three added/replaced lines across the three named files**, with **14 added/modified paths overall, 4,010 existing paths unchanged, and no deletions**. Existing test-function AST comparison also confirmed that only the fifteen intended historical test bodies changed; all other existing bodies in those modules are unchanged. The audit workflow and transferred payload are not part of the candidate. The follow-up commit only records this independent result in this report.

Raw commands/exit codes, JUnit results, before/after outcome streams, reviewed patch, preservation proof and verified candidate identity are retained in artifact **10724940052**, `historical-backlog-batch5-results`, SHA256 **3fdc76753a97ca6c1f66688f4ea1eeb5665899b99645dea35ac5eec5344eca88**. The evidence package preserves all **460 original failure/error identities**, the earlier dispositions, and the current **201-entry unresolved source-contract index**. No remaining failure is deemed harmless solely because its assertion is old.
