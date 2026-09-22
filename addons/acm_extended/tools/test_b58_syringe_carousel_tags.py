from historical_source import read_source, assert_release_identity
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def txt(rel): return read_source(ROOT/rel, encoding='utf-8',errors='replace')

def test_version_b58():
    assert_release_identity()
    p=txt('functions/fn_postInit.sqf')
    assert_release_identity()

def test_final_name_ui_removed_and_drawn_body_only():
    s=txt('functions/fn_skInject.sqf')
    assert 'Final Syringe Name (25 max)' not in s
    assert 'ctrlCreate ["ACME_SK_NameEdit", 84161]' not in s
    v=txt('functions/fn_skSetView.sqf')
    assert 'forEach [84133,84134,84302]' in v
    assert '_c ctrlShow _body' in v

def test_dedicated_syringe_menu_button_and_keys():
    s=txt('functions/fn_skInject.sqf')
    assert 'Open Syringe Menu' in s
    assert 'safeZoneH / 46' in s
    assert '_key == 30' in s and '_key == 32' in s
    v=txt('functions/fn_skSetView.sqf')
    assert 'Close Syringe Menu' in v
    assert '_carousel = _view == "carousel"' in v

def test_carousel_infinite_wrap_and_measured_plunger():
    r=txt('functions/fn_skCarouselRender.sqf')
    m=txt('functions/fn_skCarouselMove.sqf')
    assert 'mod _n' in r and 'mod _n' in m
    assert '(_amt/_size)' in r
    assert 'syringe_%1_plunger_ca.paa' in r
    assert 'ctrlCommit 0.085' in m
    assert 'ACME_SK_CarouselBusy' in m

def test_tags_have_three_editors_and_all_colors():
    s=txt('functions/fn_skInject.sqf')
    assert '84460 + _line' in s
    assert 'for "_line" from 0 to 2' in s
    colors=['yellow_induction','orange_benzodiazepine','blue_opioid','blue_stripe_reversal','red_paralytic','red_stripe_reversal','violet_vasopressor','violet_stripe_hypotensive','green_anticholinergic','gray_local_anesthetic','salmon_antiemetic','white_saline_flush']
    for c in colors: assert c in s
    assert 'Select Color' in s
    assert 'KillFocus' in s and 'KeyUp' in s

def test_tag_assets_are_paa_and_all_sizes_present():
    base=ROOT/'ui/syringe_tags'
    for size in ('1mL','3mL','5mL','10mL'):
        files=list((base/size).glob('*.paa'))
        assert len(files)==12, (size,len(files))

def test_tag_metadata_persists_on_store_and_self_menu_exists():
    assert 'set[7,_id]' in txt('functions/fn_skTagColor.sqf')
    assert 'set[8+_n' in txt('functions/fn_skTagCommit.sqf')
    c=txt('config.cpp')
    assert 'class ACME_DrawnSyringes' in c
    assert 'insertChildren = "_this call ACME_fnc_skSyringeSelfMenu";' in c
    assert 'class skSyringeSelfMenu {};' in c

def test_store_lifetime_current_life_only():
    p=txt('functions/fn_postInit.sqf')
    assert 'player addEventHandler ["Killed"' in p
    assert 'player addEventHandler ["Respawn"' in p
    assert '_unit setVariable ["ACME_narcStore", [], true]' in p

def test_carousel_headers_summary_and_patient_location():
    r=txt('functions/fn_skCarouselRender.sqf')
    assert 'ACME_fnc_skSyringeSummary' in r
    assert 'displayCtrl 84001' in r and 'displayCtrl 84002' in r
    s=txt('functions/fn_skSyringeSummary.sqf')
    assert 'Concentration' in s and ' in %4 mL' in s

def test_font_binary_not_redistributed_and_handwriting_fallback_is_runtime_safe():
    # Font file is intentionally not shipped; Arma custom fonts require generated PAA/FXY families.
    assert not list(ROOT.rglob('*.ttf'))
    cfg=txt('config.cpp')
    assert 'class ACME_SK_TagEdit: RscEdit' in cfg
    assert 'font = "Caveat";' in cfg

def test_tag_static_text_matches_editor_font_and_ad_keys_do_not_steal_typing():
    cfg=txt('config.cpp')
    inj=txt('functions/fn_skInject.sqf')
    assert 'class ACME_SK_TagText: RscText' in cfg
    assert 'private _t = _display ctrlCreate ["ACME_SK_TagText", _baseId + _x];' in inj
    assert '(ctrlIDC _focus) in [84460,84461,84462]' in inj
    assert 'exitWith {false}' in inj


def test_self_action_opens_native_size_before_entering_carousel():
    s=txt('functions/fn_skOpenStoredSyringe.sqf')
    assert 'private _size = _row param [1,10,[0]];' in s
    assert '[_size] call ACME_fnc_skOpenDraw;' in s
    assert 'ACME_SK_OpenCarouselIndex' in s
