from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(rel):
    return (ROOT / rel).read_text(errors="ignore")


def test_b42_runtime_stamp():
    assert 'version = "1.0.100-r7";' in text('config.cpp')
    p = text('functions/fn_postInit.sqf')
    assert 'ACME_buildBatch = "B43";' in p
    assert 'ACME_infusion_version = "1.0.100-r7"' in p


def test_medication_membership_uses_selected_holder_and_native_item_count_contract():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert 'ACM_circulation_MedicationVialList' in s
    assert 'ACME_fnc_vialItemCount' in s
    assert 'private _items = items _holder;' not in s
    assert 'ACME_infusion_openVials' in s


def test_medication_rows_are_independent_records_and_stock_uses_same_physical_class():
    source = text('functions/fn_medicationSourceRows.sqf')
    sync = text('functions/fn_skMedicationSync.sqf')
    refresh = text('functions/fn_skListRefresh.sqf')
    preview = text('functions/fn_vialPreview.sqf')
    assert '_rows pushBack [_label, _med, _picture, _displayClass];' in source
    assert '[_infusion] call ACME_fnc_medicationSourceRows' in sync
    assert '[_data, _reserved, _item] call _fnStockInfo' in refresh
    assert '[_holder, _med, 0, _physicalClass] call ACME_fnc_vialPreview' in refresh
    assert '["_physicalClass", "", [""]]' in preview


def test_vial_parser_keeps_full_suffix():
    s = text('functions/fn_vialMedication.sqf')
    assert '["_vial_", "_ampule_"]' in s
    assert '_class select [_at + count _needle]' in s
    assert 'splitString "_"' not in s
    assert 'ACM_Ampule_Dimercaprol' in text('functions/fn_vialClass.sqf')


def test_auscultate_chest_keeps_group_child_indent():
    s = text('overrides/fn_updateActions.sqf')
    assert "_actionClass == 'usestethoscope'" in s
    assert "format ['%1Auscultate Chest'" in s
    assert "missionNamespace getVariable ['ACME_menuChildIndent', '        ']" in s
    assert '["examine_chest", "Chest Inspection"' in text('functions/fn_menuExamineGroups.sqf')


def test_direct_pressure_activity_log_exact_limb_wording():
    limb = text('functions/fn_directPressureLimb.sqf')
    assert '"%1 started Direct pressure on %2"' in limb
    assert '[_bodyPart, "abbr"] call ACME_fnc_bodyPartName' in limb
    body = text('functions/fn_bodyPartName.sqf')
    for short in ('LUE', 'RUE', 'LLE', 'RLE'):
        assert f'"{short}"' in body


def test_direct_pressure_torso_self_and_stop_use_same_log_grammar():
    assert '"%1 started Direct pressure on %2"' in text('functions/fn_directPressureTorso.sqf')
    assert '"%1 started Direct pressure on own %2"' in text('functions/fn_directPressureSelf.sqf')
    assert '"%1 stopped Direct pressure on %2"' in text('functions/fn_directPressureStop.sqf')


def test_audit_removed_stale_lidocaine_latch_read_and_preserved_live_effect_lookup():
    s = text('functions/fn_rhythmThresholdTick.sqf')
    assert 'getVariable ["ACME_rhythm_lidoLastTherapeutic"' not in s
    assert 'ace_medical_medications' in s
    assert 'ACME_fnc_lidoEffectiveness' in s


def test_nv_texture_map_uses_exact_local_asset_case_for_known_case_sensitive_entries():
    s = text('functions/fn_minigameVisionTextures.sqf')
    for p in ('HPMK_ca.paa', 'HPMK_unwrapped.paa', 'HPMK_unwrapped_ca.paa', 'salineFlush_ca.paa'):
        assert '\\acm_extended\\ui\\items\\' + p in s


def test_extended_fentanyl_source_capacity_matches_500mcg_10ml_inventory_item():
    s = text('config.cpp')
    assert 'displayName = "Fentanyl (500mcg/10ml)";' in s
    concentration = s[s.index('class Concentration {', s.index('class ACM_Medication')):]
    assert 'class Fentanyl {' in concentration
    block = concentration[concentration.index('class Fentanyl {'):concentration.index('};', concentration.index('class Fentanyl {')) + 2]
    assert 'concentration = 0.05;' in block
    assert 'dose = "500mcg/10ml";' in block
    assert 'volume = 10;' in block
