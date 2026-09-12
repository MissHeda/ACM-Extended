from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def txt(rel):
    return (ROOT / rel).read_text(encoding='utf-8', errors='replace')

def test_b62_version_stamp_and_functions():
    cfg = txt('config.cpp')
    post = txt('functions/fn_postInit.sqf')
    assert 'version = "1.0.100-r26";' in cfg
    assert 'ACME_infusion_version = "1.0.100-r26"' in post
    assert 'ACME_buildBatch = "B62";' in post
    assert 'class skTagEditOpen {};' in cfg
    assert 'class skTagEditDone {};' in cfg

def test_main_draw_select_tag_is_beside_native_syringe_not_left_list():
    inj = txt('functions/fn_skInject.sqf')
    pending = txt('functions/fn_skPendingTagRender.sqf')
    assert '_pendingTagBtn ctrlSetPosition [0,0,0,0];' in inj
    assert '_btnX = _x + _w + _gap' in pending
    assert '_button ctrlSetText "Select Tag";' in pending
    assert 'Select Tag:' not in pending
    assert 'safeZoneH * 0.78' in pending
    assert 'safeZoneW * 0.30' in pending

def test_both_tag_dropdowns_have_single_click_fallback_and_none():
    inj = txt('functions/fn_skInject.sqf')
    assert inj.count('"MouseButtonUp"') >= 2
    assert inj.count('["none","None - No syringe tag"]') >= 2
    assert '[_ctrl,_row] call ACME_fnc_skTagColor' in inj
    assert '[_ctrl,_row] call ACME_fnc_skPendingTagColor' in inj

def test_carousel_button_is_edit_tag_and_editor_button_is_select_tag():
    render = txt('functions/fn_skCarouselRender.sqf')
    assert 'if (_editMode) then {"Select Tag"} else {"Edit Tag"}' in render
    assert 'Select Color' not in render
    assert 'Select Color' not in txt('functions/fn_skInject.sqf')

def test_dedicated_edit_tag_mode_uses_native_draw_size_and_auto_focuses_first_line():
    render = txt('functions/fn_skCarouselRender.sqf')
    opn = txt('functions/fn_skTagEditOpen.sqf')
    done = txt('functions/fn_skTagEditDone.sqf')
    assert '_fullW = _native select 2;' in render
    assert '_fullH = _native select 3;' in render
    assert 'ctrlSetFocus _e' in opn
    assert 'ACME_SK_TagEditMode", true' in opn
    assert 'ctrlSetText "Done"' in txt('functions/fn_skInject.sqf')
    assert 'ACME_SK_CarouselExpanded", false' in done
    assert 'ACME_SK_TagEditMode", false' in done

def test_tag_edits_do_not_repaint_on_every_keypress_and_fields_are_transparent():
    commit = txt('functions/fn_skTagCommit.sqf')
    render = txt('functions/fn_skCarouselRender.sqf')
    pending = txt('functions/fn_skPendingTagRender.sqf')
    assert 'if !(uiNamespace getVariable ["ACME_SK_TagEditMode",false]) then {call ACME_fnc_skRefreshDrawn;};' in commit
    assert 'ctrlSetBackgroundColor [0,0,0,0]' in render
    assert 'ctrlSetBackgroundColor [0,0,0,0]' in pending

def test_wide_carousel_retention_zone_spans_route_to_draw_workspace():
    inj = txt('functions/fn_skInject.sqf')
    layout = txt('functions/fn_skDynamicLayout.sqf')
    tick = txt('functions/fn_skUiTick.sqf')
    assert 'ctrlCreate ["ACME_SK_HotspotButton", 84481]' in inj
    assert 'private _zoneY = _routeY + _th + safeZoneH*0.006;' in layout
    assert 'private _zoneBottom = _viewY - safeZoneH*0.008;' in layout
    assert '_zone ctrlSetPosition [_carX,_zoneY,_carW,_zoneH];' in layout
    assert 'ACME_SK_CarouselZoneHover' in tick
    assert '_hover || {_zoneHover}' in tick

def test_compact_syringes_are_larger_and_carousel_is_tighter_on_ultrawide():
    inj = txt('functions/fn_skInject.sqf')
    render = txt('functions/fn_skCarouselRender.sqf')
    assert '(safeZoneW * 0.40) min (safeZoneH * 1.08)' in inj
    assert '(safeZoneW * 0.46) min (safeZoneH * 1.22)' in inj
    assert 'safeZoneH*0.132' in inj
    assert 'safeZoneH*0.405' in inj
    assert 'if (_expanded) then {0.94} else {0.98}' in render
    assert '[0.24,0.48,1.0,0.48,0.24]' in render

def test_body_moves_down_and_shrinks_more_during_promoted_carousel():
    inj = txt('functions/fn_skInject.sqf')
    layout = txt('functions/fn_skDynamicLayout.sqf')
    assert 'safeZoneH * 0.26 / _fillV' in inj
    assert 'safeZoneH*0.032' in inj
    assert 'safeZoneH*0.100' in inj
    assert 'if (_expanded) then {0.455} else {0.748}' in layout

def test_active_syringe_still_85_percent_and_hover_is_100_percent_with_bigger_target():
    render = txt('functions/fn_skCarouselRender.sqf')
    assert '0.85' in render
    assert '_scale = _scale * 1.10; _alpha = 1;' in render
    assert '_fullW * 1.45' in render
    assert '_fullH * 1.20' in render

def test_edit_mode_disables_neighbor_selection_and_injection_hotspots():
    render = txt('functions/fn_skCarouselRender.sqf')
    build = txt('functions/fn_skBuildHotspots.sqf')
    move = txt('functions/fn_skCarouselMove.sqf')
    pick = txt('functions/fn_skCarouselPick.sqf')
    assert '_hit ctrlShow (!_editMode); _hit ctrlEnable (!_editMode);' in render
    assert '!_tagEditMode' in build
    assert 'ACME_SK_TagEditMode",false]) exitWith {};' in move
    assert 'ACME_SK_TagEditMode",false]) exitWith {};' in pick

def test_hover_tooltip_remains_exact_three_written_tag_lines():
    render = txt('functions/fn_skCarouselRender.sqf')
    assert '_e param [8,"",[""]]' in render
    assert '_e param [9,"",[""]]' in render
    assert '_e param [10,"",[""]]' in render
    assert 'joinString (toString [10])' in render
