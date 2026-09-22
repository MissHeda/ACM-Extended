from historical_source import read_source, assert_release_identity
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
def text(rel):
    return read_source(ROOT / rel, errors="ignore")


def test_b45_version_stamp():
    assert_release_identity()
    p = text('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()


def test_medication_source_uses_real_acm_registry_and_inventory_first():
    # The native class catalog plus the selected inventory counter is current policy,
    # not the retired independent uniqueItems enumeration or a literal macro-name variable.
    from test_historical_medication_rows import test_rows_follow_selected_inventory_and_never_manufacture_stock, test_vehicle_rows_use_cargo_counts_not_the_provider_inventory
    for holder in ['_medic','_patient','objNull']:
        test_rows_follow_selected_inventory_and_never_manufacture_stock(holder)
    test_vehicle_rows_use_cargo_counts_not_the_provider_inventory()


def test_postinit_snapshots_actual_native_registry():
    from test_historical_medication_rows import test_initializer_publishes_real_native_catalog_and_snapshot, test_restore_repairs_the_real_native_registry_without_mutating_snapshot
    test_initializer_publishes_real_native_catalog_and_snapshot('[]')
    test_restore_repairs_the_real_native_registry_without_mutating_snapshot('[]')


def test_medication_column_visible_in_body_and_infusion_views():
    r = text('functions/fn_skListRefresh.sqf')
    assert 'private _visible = true;' in r
    assert '!(_kind == "medication" && {_body})' not in r
    v = text('functions/fn_skSetView.sqf')
    assert '(_display displayCtrl 84007) ctrlShow (!_infusion);' in v
    assert '(_display displayCtrl 84008) ctrlShow true;' in v
    # Infusion prep may hide flush/drawn rows, but never medication rows.
    assert 'if (_infusion && {_kind in ["flush", "drawn"]}) then {_visible = false;};' in r


def test_narc_box_vascular_highlight_matches_acm_green():
    s = text('functions/fn_skBuildHotspots.sqf')
    assert 'private _vascularColor = [0.20, 0.65, 0.20, 0.42];' in s
    assert 'private _green = [0.20,0.65,0.20,0.92];' in s
    assert 'private _tint = +_vascularColor;' in s
    assert 'private _tint = +_imColor;' in s


def test_stethoscope_dialog_does_not_depend_on_pose_episode():
    s = text('functions/fn_beginStethoscopeAction.sqf')
    assert 'private _poseEnded' not in s
    cancel = s[s.index('if (_patientCondition'):]
    assert '_poseEnded' not in cancel
    assert 'if (_key == 0x01)' in s
    assert 'ACM_core_ContinuousAction_ShouldReopen = true;' in s
    assert 'if (_key == 0x23) exitWith {true};' in s
    assert 'ACM_core_openMedicalMenu' in s


def test_io_insertion_has_moderate_floor_and_fluid_has_max_pain_syncope():
    s = text('functions/fn_ioPainResponse.sqf')
    assert '"placement"' in s
    assert 'ACME_ioInsertionMinPain' in s
    assert 'ace_medical_pain", 1, true' in s
    assert 'ACME_ioFluidSyncopeDelay' in s
    assert 'ace_medical_status_fnc_setUnconsciousState' in s
    p = text('functions/fn_postInit.sqf')
    assert 'ACME_ioInsertionMinPain = 0.35;' in p
    assert 'ACME_ioFluidSyncopeDelay = 3;' in p
    assert '"ACM_circulation_setIVLocal"' in p
    assert '[_patient, _bodyPart, "placement"] call ACME_fnc_ioPainResponse;' in p


def test_io_pain_fires_on_actual_bag_volume_and_exact_io_pushes():
    b = text('overrides/fn_getBloodVolumeChange.sqf')
    assert 'if (_admitted > 0 && {_accessType in [ACM_IO_FAST1_M, ACM_IO_EZ_M]})' in b
    assert '[_unit, _targetBodyPart, "fluid"] call ACME_fnc_ioPainResponse;' in b
    p = text('functions/fn_postInit.sqf')
    assert 'whole-unit watcher is removed' in p
    m = text('functions/fn_medicationLineLocal.sqf')
    assert 'if (_iv && {_site == -1}) then {[_patient, _bodyPart, "fluid"] call ACME_fnc_ioPainResponse;};' in m


def test_chest_seal_public_wrapper_duplicate_removed():
    s = text('functions/fn_chestSealEffectLocal.sqf')
    assert 'call ACM_breathing_fnc_applyChestSealLocal;' in s
    assert 'call ACM_breathing_fnc_applyChestSeal;' not in s
    assert 'ACME_fnc_chestSealLogOnce' in s
    assert 'class chestSealLogOnce {};' in text('config.cpp')


def test_chest_seal_log_channels_are_independent_and_cooled_down():
    h = text('functions/fn_chestSealLogOnce.sqf')
    for action in ['case "apply"', 'case "burp"', 'case "remove"']:
        assert action in h
    p = text('functions/fn_postInit.sqf')
    assert 'ACME_chestSealApplyLogCooldown = 30;' in p
    assert 'ACME_chestSealBurpLogCooldown = 10;' in p
    assert 'ACME_chestSealRemoveLogCooldown = 10;' in p
    b = text('functions/fn_chestSealBurp.sqf')
    assert '"burp", "Burped chest seal"' in b
