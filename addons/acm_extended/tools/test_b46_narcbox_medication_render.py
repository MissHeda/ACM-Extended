from historical_source import read_source, assert_release_identity
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(rel):
    return read_source(ROOT / rel, errors="ignore")


def test_b46_version_stamp():
    assert_release_identity()
    p = text('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()


def test_b38_runtime_title_bar_is_removed_from_renderer():
    s = text('functions/fn_skListRefresh.sqf')
    assert 'ACME_SK_ColumnHeader' not in s
    assert '_headerBack' not in s
    assert '_headerContents' not in s
    assert '_headerCount' not in s
    assert 'forEach [84007,84008]' not in s
    # Source selector controls must stay at ACM's original dialog geometry.
    assert '_pos set [1, (_pos select 1) - _headerH]' not in s


def test_separate_count_child_control_is_removed():
    s = text('functions/fn_skListRefresh.sqf')
    assert '_countText' not in s
    assert 'ctrlCreate ["ACME_SK_RightText"' not in s
    assert '["%1 mL  x%2", _curMl toFixed 2, _count]' in s
    assert '_stock ctrlSetPosition [_innerW - _stockW, _cursorY, _stockW, _rowH];' in s


def test_tick_updates_one_combined_stock_control():
    s = text('functions/fn_skUiTick.sqf')
    assert '_countText' not in s
    assert '_stock ctrlSetText format ["%1 mL  x%2", _curMl toFixed 2, _cnt];' in s


def test_medication_label_has_nonblank_config_and_key_fallback():
    s = text('functions/fn_skListRefresh.sqf')
    block = s.split('if (_kind == "medication") then {', 1)[1].split('    } else {', 1)[0]
    # Populated medication presentation remains immutable and cannot be rebound from a mutable ACM list row.
    assert 'forEach _medRows' in block
    assert '_list lbText' not in block
    assert '_list lbPicture' not in block
    assert 'if (_labelSafe == "") then {_labelSafe = getText (_cfg >> "displayName");};' in block
    assert 'if (_labelSafe == "") then {_labelSafe = _data;};' in block


def test_b45_backend_registry_fix_is_retained():
    s = text('functions/fn_medicationSourceRows.sqf')
    assert 'ACM_MEDICATION_VIALS' in s
    assert 'ace_common_fnc_uniqueItems' in s
    assert 'if (_sealed <= 0 && {_openMl <= 0.000001}) then {continue};' in s


def test_medication_group_stays_visible_in_body_and_infusion_paths():
    s = text('functions/fn_skListRefresh.sqf')
    assert 'private _visible = true;' in s
    assert '!(_kind == "medication" && {_body})' not in s
    assert 'if (_infusion && {_kind in ["flush", "drawn"]}) then {_visible = false;};' in s
