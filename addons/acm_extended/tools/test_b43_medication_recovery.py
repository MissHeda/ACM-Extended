from historical_source import read_source, assert_release_identity
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(rel):
    return read_source(ROOT / rel, errors='ignore')


def test_b43_runtime_stamp():
    assert_release_identity()
    p = text('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()


def test_medication_membership_uses_native_ace_item_count_path():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert "ACM_circulation_MedicationVialList" in s
    assert 'ACME_fnc_vialItemCount' in s
    assert 'private _items = items _holder;' not in s
    assert 'uniformContainer _holder' not in s
    assert 'vestContainer _holder' not in s
    assert 'backpackContainer _holder' not in s
    assert 'ACME_infusion_openVials' in s


def test_medication_source_has_registry_fallback_but_not_parallel_global_swap():
    from test_historical_medication_rows import test_catalog_fallbacks_and_duplicate_entries_do_not_change_medication_identity, test_infusion_filter_uses_current_allow_lists_without_mutating_global_catalog
    for live,snapshot in [('[]','[]'),('[]','["ACM_Vial_Ketamine"]')]:
        test_catalog_fallbacks_and_duplicate_entries_do_not_change_medication_identity(live,snapshot)
    for mode in [False,True]:
        test_infusion_filter_uses_current_allow_lists_without_mutating_global_catalog(mode)


def test_invalid_inventory_source_falls_back_to_self_instead_of_ghost_rows():
    from test_vial_holder_fallback_20260922 import test_missing_patient_or_vehicle_source_normalizes_the_real_selector, test_reachable_dead_patient_source_waits_for_ack_and_does_not_silently_select_self, test_unreachable_source_releases_its_old_lease_and_normalizes_the_selector
    for selection in [1,2]:
        test_missing_patient_or_vehicle_source_normalizes_the_real_selector(selection)
    test_reachable_dead_patient_source_waits_for_ack_and_does_not_silently_select_self()
    test_unreachable_source_releases_its_old_lease_and_normalizes_the_selector()


def test_rows_are_only_emitted_for_positive_physical_or_open_stock():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert "private _sealed = [_holder, _class] call ACME_fnc_vialItemCount;" in s
    assert "private _openMl = (_open getOrDefault [_med, 0]) max 0;" in s
    assert 'if (_sealed <= 0 && {_openMl <= 0.000001}) then {continue};' in s
    assert '_rows pushBack [_label, _med, _picture, _displayClass];' in s


def test_hidden_native_selector_and_visible_rows_share_same_records():
    from test_historical_medication_rows import test_native_sync_rebuilds_empty_selector_once_and_preserves_each_medication, test_visible_rows_bind_metadata_by_key_and_recover_missing_backing_entries
    test_native_sync_rebuilds_empty_selector_once_and_preserves_each_medication()
    test_visible_rows_bind_metadata_by_key_and_recover_missing_backing_entries('[]')


def test_repeated_drug_regression_cannot_rebind_presentation_from_listbox():
    # Metadata is looked up by medication key even after reordering or duplicate native rows.
    from test_historical_medication_rows import test_visible_rows_bind_metadata_by_key_and_recover_missing_backing_entries, test_sync_restores_selection_by_medication_key_not_row_index
    test_visible_rows_bind_metadata_by_key_and_recover_missing_backing_entries('[["Fentanyl native","Fentanyl",""],["duplicate","Fentanyl","bad.paa"],["","Ketamine",""]]')
    for selected in [0,1]:
        test_sync_restores_selection_by_medication_key_not_row_index(selected)


def test_cardio_epi_alias_is_counted_once_and_displayed_as_acme():
    from test_historical_medication_rows import test_epinephrine_alias_is_one_row_with_canonical_presentation
    for source in ['legacy','extended','both','partial']:
        test_epinephrine_alias_is_one_row_with_canonical_presentation(source)
