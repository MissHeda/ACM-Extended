from historical_source import read_source, assert_release_identity
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def txt(rel):
    return read_source(ROOT / rel, encoding="utf-8-sig", errors="ignore")


def test_version_and_batch():
    assert_release_identity()
    p = txt('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()


def test_three_column_header_is_retained():
    s = txt('functions/fn_skListRefresh.sqf')
    assert 'ACME_SK_ColumnHeader' in s
    for caption in ['"Medication"', '"Contents"', '"Vials"']:
        assert caption in s
    assert '[84006,84303,"medication"]' in s


def test_visible_medication_identity_comes_from_native_row_with_fallbacks():
    s = txt('functions/fn_skListRefresh.sqf')
    branch = s[s.index('B51: bind the visible three-column row'):s.index('    private _rows = _group getVariable', s.index('B51: bind the visible three-column row'))]
    assert '_list lbText _i' in branch
    assert '_list lbData _i' in branch
    assert '_list lbPicture _i' in branch
    assert 'ACME_SK_MedicationRows' in branch
    assert 'if (_label == "") then {_label = _data;};' in branch
    assert '_data == ""' in branch
    assert 'Last-mile B51 guard' in s
    assert 'getText (_itemCfg >> "displayName")' in s
    assert '_data = [_item] call ACME_fnc_vialMedication' in s


def test_native_backing_rows_cannot_intentionally_add_blank_medication_data():
    s = txt('functions/fn_skMedicationSync.sqf')
    assert 'if (_med == "") then {continue};' in s
    assert 'if (_label == "") then {_label = _med;};' in s
    assert '_list lbSetData [_i, _med];' in s


def test_vial_capacity_has_config_authority_and_defensive_known_vial_fallbacks():
    s = txt('functions/fn_vialCapacity.sqf')
    assert 'configFile >> "ACM_Medication" >> "Concentration" >> _med >> "volume"' in s
    for med, cap in [
        ('Epinephrine', '1'), ('EpinephrineCardiac', '10'), ('Fentanyl', '10'),
        ('Ketamine', '10'), ('Propofol', '50'), ('CalciumGluconate', '50'),
        ('Rocuronium', '10'), ('Sugammadex', '5'), ('Norepinephrine', '4')
    ]:
        assert f'["{med}", {cap}]' in s
    assert 'class vialCapacity {};' in txt('config.cpp')


def test_all_vial_math_paths_use_one_capacity_resolver():
    for rel in [
        'functions/fn_vialPreview.sqf',
        'functions/fn_vialSession.sqf',
        'functions/fn_vialTake.sqf',
        'functions/fn_infusionVialVolume.sqf',
    ]:
        s = txt(rel)
        assert '[_med] call ACME_fnc_vialCapacity' in s, rel


def test_visible_stock_has_physical_inventory_fail_safe():
    s = txt('functions/fn_skListRefresh.sqf')
    assert 'physical item that created this row is indisputable stock evidence' in s
    assert '[_holder, _physicalClass] call ACME_fnc_vialItemCount' in s
    assert 'private _cap = [_med] call ACME_fnc_vialCapacity;' in s
    assert '_vials = _directCount;' in s
    assert '_curMl = _cap;' in s


def test_flush_art_only_replaces_barrel_for_actual_flush_draw():
    s = txt('functions/fn_skOpenDraw.sqf')
    assert 'private _barrelTexture = if (_flushClass != "") then {' in s
    assert '"\\acm_extended\\ui\\syringe\\syringe_flush_10_barrel_ca.paa"' in s
    assert '"\\x\\ACM\\addons\\circulation\\ui\\syringe\\syringe_10_barrel_ca.paa"' in s


def test_intubation_still_uses_flush_barrel_art():
    s = txt('config.cpp')
    # The laryngoscopy cuff syringe is intentionally the other user-approved use of the new barrel.
    assert 'idc = 87818;' in s
    start = s.index('idc = 87818;')
    block = s[start:start+1000]
    assert '\\acm_extended\\ui\\syringe\\syringe_flush_10_barrel_ca.paa' in block


def test_b50_prepared_set_and_prep_infusion_gates_remain():
    s = txt('functions/fn_updateTransfusionControls.sqf')
    assert 'Prepared IV sets (%1)' in s
    assert 'ACME_fnc_isSalineItem' in s
    p = txt('functions/fn_openPrepFromInventoryMenu.sqf')
    assert 'if (!_preparedMode) exitWith' in p
    assert 'Only a selected normal saline set can be prepared into an infusion.' in p
