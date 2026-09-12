from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(rel):
    return (ROOT / rel).read_text(errors='ignore')


def test_b43_runtime_stamp():
    assert 'version = "1.0.100-r7";' in text('config.cpp')
    p = text('functions/fn_postInit.sqf')
    assert 'ACME_buildBatch = "B43";' in p
    assert 'ACME_infusion_version = "1.0.100-r7"' in p


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
    s = text('functions/fn_medicationSourceRows.sqf')
    assert 'ACME_medicationVialRegistryFull' in s
    assert 'configClasses' in s
    post = text('functions/fn_postInit.sqf')
    assert 'snapshot ACM\'s own finalized vial registry' in post
    open_draw = text('functions/fn_openDrawMenu.sqf')
    assert 'Do not mutate ACM\'s global vial registry' in open_draw


def test_invalid_inventory_source_falls_back_to_self_instead_of_ghost_rows():
    s = text('functions/fn_vialHolder.sqf')
    assert 'if (isNull _holder) then {' in s
    assert "_holder = _medic;" in s
    assert "ACM_circulation_SyringeDraw_InventorySelection" in s
    assert "setVariable ['ACM_circulation_SyringeDraw_InventorySelection', 0]" in s


def test_rows_are_only_emitted_for_positive_physical_or_open_stock():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert "private _sealed = [_holder, _class] call ACME_fnc_vialItemCount;" in s
    assert "private _openMl = (_open getOrDefault [_med, 0]) max 0;" in s
    assert 'if (_sealed <= 0 && {_openMl <= 0.000001}) then {continue};' in s
    assert '_rows pushBack [_label, _med, _picture, _displayClass];' in s


def test_hidden_native_selector_and_visible_rows_share_same_records():
    sync = text('functions/fn_skMedicationSync.sqf')
    refresh = text('functions/fn_skListRefresh.sqf')
    assert '[_infusion] call ACME_fnc_medicationSourceRows' in sync
    assert '_display setVariable ["ACME_SK_MedicationRows", +_rows];' in sync
    assert 'private _medRows = [_d] call ACME_fnc_skMedicationSync;' in refresh
    assert '_x params ["_labelNow", "_data", "_pictureNow", "_item"];' in refresh


def test_repeated_drug_regression_cannot_rebind_presentation_from_listbox():
    refresh = text('functions/fn_skListRefresh.sqf')
    # medication rows come from immutable source records, not lbText/lbPicture of the selected row
    start = refresh.index('if (_kind == "medication") then {')
    end = refresh.index('    } else {', start)
    block = refresh[start:end]
    assert 'forEach _medRows' in block
    assert '_list lbText' not in block
    assert '_list lbPicture' not in block


def test_cardio_epi_alias_is_counted_once_and_displayed_as_acme():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert "'ACME_Vial_EpinephrineCardiac'" in s
    assert "'ACM_Vial_EpinephrineCardiac'" in s
    assert "if (_med == 'EpinephrineCardiac')" in s
