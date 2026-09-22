from historical_source import read_source, assert_release_identity
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def txt(rel):
    return read_source(ROOT / rel, encoding='utf-8', errors='replace')

def test_b60_version_and_new_functions_registered():
    cfg = txt('config.cpp')
    post = txt('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()
    for fn in (
        'skApplyPendingTag','skPendingTagReset','skPendingTagCommit','skPendingTagColor',
        'skPendingTagRender','skAfterSaveOpenBody','skDynamicLayout','skCarouselHover','skCarouselPick'
    ):
        assert f'class {fn} {{}};' in cfg

def test_body_and_carousel_have_compact_and_expanded_geometry():
    inj = txt('functions/fn_skInject.sqf')
    layout = txt('functions/fn_skDynamicLayout.sqf')
    for token in ('ACME_SK_BodyRectCompact','ACME_SK_BodyRectExpanded','ACME_SK_CarouselRectCompact','ACME_SK_CarouselRectExpanded'):
        assert token in inj and token in layout
    assert 'safeZoneH*0.70' in inj
    assert 'safeZoneH*0.49' in inj
    assert 'ctrlCommit _duration' in layout
    assert 'ACME_SK_LayoutBusyUntil' in layout

def test_ad_expands_carousel_and_auto_collapse_is_hover_aware():
    inj = txt('functions/fn_skInject.sqf')
    move = txt('functions/fn_skCarouselMove.sqf')
    tick = txt('functions/fn_skUiTick.sqf')
    hover = txt('functions/fn_skCarouselHover.sqf')
    assert 'case 30: {-1}' in inj and 'case 32: {1}' in inj
    assert 'ACME_SK_CarouselExpanded",true' in move
    assert 'ACME_fnc_skDynamicLayout' in move
    assert 'ACME_SK_CarouselCollapseAt' in move
    assert 'ACME_SK_CarouselHover' in tick
    assert '_editingTag' in tick and '_colorOpen' in tick and '_heldDir != 0' in tick
    assert 'ACME_SK_CarouselExpanded", false' in tick
    assert '[0.12] call ACME_fnc_skDynamicLayout' in tick
    assert 'diag_tickTime + 0.28' in hover

def test_active_syringe_is_85_percent_then_100_percent_on_hover():
    car = txt('functions/fn_skCarouselRender.sqf')
    assert '[0.20,0.44,0.85,0.44,0.20]' in car
    assert '[0.14,0.32,0.85,0.32,0.14]' in car
    assert '_slot == 2 && {_hover}' in car
    assert '_scale = _scale * 1.055; _alpha = 1;' in car
    assert 'private _activeScale = if (_hover) then {1.055} else {1};' in car

def test_same_five_carousel_controls_are_used_in_both_layouts():
    inj = txt('functions/fn_skInject.sqf')
    car = txt('functions/fn_skCarouselRender.sqf')
    assert 'for "_slot" from 0 to 4' in inj
    assert '84400 + (_slot * 10)' in inj
    assert 'ACME_SK_CarouselRect' in car
    assert 'if (_expanded)' in car
    # B59's separate lower mini-carousel is explicitly retired.
    assert 'ctrlCreate ["RscPicture", 84500' not in inj

def test_clicking_visible_syringe_selects_stable_record_and_expands():
    pick = txt('functions/fn_skCarouselPick.sqf')
    ensure = txt('functions/fn_skStoreEnsureIds.sqf')
    selected = txt('functions/fn_skSelectedIndex.sqf')
    assert 'ACME_fnc_skSelectStored' in pick
    assert 'ACME_SK_CarouselExpanded",true' in pick
    assert 'ACME_SK_SiteIdx",-1' in pick
    assert '_row set [11, _id]' in ensure
    assert 'param [11, "", [""]]' in selected

def test_preparation_has_optional_none_tag_and_three_invisible_editors():
    inj = txt('functions/fn_skInject.sqf')
    render = txt('functions/fn_skPendingTagRender.sqf')
    cfg = txt('config.cpp')
    assert 'Tag: None' in inj
    assert '["none","None - No syringe tag"]' in inj
    for idc in ('84600','84601','84602','84603','84610','84611'):
        assert idc in inj
    assert 'for "_line" from 0 to 2' in inj
    assert 'colorBackground[] = {0,0,0,0};' in cfg
    assert '_e ctrlShow _hasTag' in render
    assert 'tag_overlay_%1mL_%2.paa' in render

def test_all_requested_tag_colors_are_available_during_preparation():
    inj = txt('functions/fn_skInject.sqf')
    colors = [
        'yellow_induction','orange_benzodiazepine','blue_opioid','blue_stripe_reversal',
        'red_paralytic','red_stripe_reversal','violet_vasopressor','violet_stripe_hypotensive',
        'green_anticholinergic','gray_local_anesthetic','salmon_antiemetic','white_saline_flush'
    ]
    for color in colors:
        assert color in inj

def test_pending_tag_is_applied_to_every_narcbox_save_path():
    apply = txt('functions/fn_skApplyPendingTag.sqf')
    assert '_out set [7, _color]' in apply
    assert '_out set [8 + _i' in apply
    for rel in (
        'functions/fn_skCompoundCommit.sqf',
        'functions/fn_skWasteDraw.sqf',
        'functions/fn_epinephrineDrawCardiac.sqf',
        'overrides/fn_syringeDrawButton.sqf',
    ):
        assert 'ACME_fnc_skApplyPendingTag' in txt(rel), rel
    assert 'ACME_fnc_skApplyPendingTag' in txt('functions/fn_epinephrinePrepare.sqf')

def test_save_returns_to_large_body_and_compact_carousel():
    after = txt('functions/fn_skAfterSaveOpenBody.sqf')
    compound = txt('functions/fn_skCompoundSave.sqf')
    waste = txt('functions/fn_skWasteDraw.sqf')
    direct = txt('overrides/fn_syringeDrawButton.sqf')
    assert 'ACME_SK_CarouselExpanded", false' in after
    assert 'ACME_SK_View", "body"' in after
    assert 'ACME_fnc_skSetView' in after
    assert '[true] call ACME_fnc_skAfterSaveOpenBody' in compound
    assert '[true] call ACME_fnc_skAfterSaveOpenBody' in waste
    assert 'call ACME_fnc_skAfterSaveOpenBody' in direct

def test_total_solution_volume_drives_stored_plunger_position():
    car = txt('functions/fn_skCarouselRender.sqf')
    assert '(_amt + _nsMl) / (_size max 0.01)' in car
    assert 'ACME_SK_CarouselTravel10' in car
    assert 'syringe_%1_plunger_ca.paa' in car

def test_tag_editing_does_not_steal_ad_typing_and_holds_expanded_view():
    inj = txt('functions/fn_skInject.sqf')
    tick = txt('functions/fn_skUiTick.sqf')
    assert '(ctrlIDC _focus) in [84460,84461,84462,84601,84602,84603]' in inj
    assert 'exitWith {false}' in inj
    assert '(ctrlIDC _focus) in [84460,84461,84462]' in tick
    assert 'ctrlShown (_d displayCtrl 84471)' in tick

def test_body_hitboxes_wait_for_layout_animation_to_finish():
    hot = txt('functions/fn_skBuildHotspots.sqf')
    assert 'ACME_SK_LayoutBusyUntil' in hot
    assert '_layoutReady' in hot

def test_store_still_expires_on_death_and_respawn():
    post = txt('functions/fn_postInit.sqf')
    assert 'player addEventHandler ["Killed"' in post
    assert 'player addEventHandler ["Respawn"' in post
    assert '_unit setVariable ["ACME_narcStore", [], true]' in post
    assert 'ACME_SK_SelectedSyringeId", ""' in post
