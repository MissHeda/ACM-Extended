from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def txt(rel):
    return (ROOT / rel).read_text(encoding='utf-8', errors='replace')

def test_b63_version_stamp():
    assert 'version = "1.0.100-r27";' in txt('config.cpp')
    post = txt('functions/fn_postInit.sqf')
    assert 'ACME_infusion_version = "1.0.100-r27"' in post
    assert 'ACME_buildBatch = "B63";' in post

def test_tag_editors_are_frameless_short_and_raised():
    cfg = txt('config.cpp')
    car = txt('functions/fn_skCarouselRender.sqf')
    pending = txt('functions/fn_skPendingTagRender.sqf')
    assert 'style = 0x00;' in cfg
    assert 'colorBorder[] = {0,0,0,0};' in cfg
    assert 'borderSize = 0;' in cfg
    assert 'private _lineY = [0.452,0.482,0.504];' in car
    assert '_ah*0.020' in car
    assert 'private _lineY = [0.452,0.482,0.504];' in pending
    assert '_h * 0.020' in pending

def test_stored_tag_editor_raises_native_syringe_and_places_select_tag_under_tag():
    car = txt('functions/fn_skCarouselRender.sqf')
    assert 'safeZoneH*0.285' in car
    assert 'private _tagCenterX = _ax + _aw*0.36;' in car
    assert '_btnY = _ay + _ah*0.575;' in car
    assert 'if (_editMode) then {"Select Tag"} else {"Edit Tag"}' in car

def test_body_map_edit_tag_is_above_syringe_below_route():
    car = txt('functions/fn_skCarouselRender.sqf')
    assert 'private _routeRect = ctrlPosition (_d displayCtrl 84151);' in car
    assert 'private _routeBottom' in car
    assert '_btnY = (_ay - _btnH - _gap) max (_routeBottom + safeZoneH*0.004);' in car

def test_main_draw_select_tag_is_under_live_tag_and_has_wide_clickable_dropdown():
    inj = txt('functions/fn_skInject.sqf')
    pending = txt('functions/fn_skPendingTagRender.sqf')
    assert 'private _pendingTagPic = _display ctrlCreate ["RscPicture", 84600];' in inj
    # z-order: live art/editors before list, list before button
    assert inj.index('private _pendingTagPic') < inj.index('private _pendingTagList') < inj.index('private _pendingTagBtn')
    assert 'private _tagCenterX = _x + _w * 0.36;' in pending
    assert 'private _btnY = _y + _h * 0.575;' in pending
    assert '(safeZoneH * 0.95) min (safeZoneW * 0.34)' in pending
    assert 'ctrlSetFocus _l' in inj
    assert 'LBSelChanged' in inj and 'MouseButtonUp' in inj

def test_pending_tag_live_preview_remains_available_to_saline_flush_flow():
    pending = txt('functions/fn_skPendingTagRender.sqf')
    waste = txt('functions/fn_skWasteDraw.sqf')
    pick = txt('functions/fn_skPickFlush.sqf')
    assert '(_view == "syringe") && {!_infusion}' in pending
    assert 'tag_overlay_%1mL_%2.paa' in pending
    assert 'ACME_fnc_skApplyPendingTag' in waste
    assert '[10, _patient, _bodyPart, _flushClass]' in pick

def test_draw_and_save_have_physical_press_feedback():
    inj = txt('functions/fn_skInject.sqf')
    assert 'ACME_SK_PressFeedbackBound' in inj
    assert '"MouseButtonDown"' in inj
    assert '"MouseButtonUp"' in inj
    assert '"MouseExit"' in inj
    assert 'forEach [84003,84004]' in inj
    assert '2*pixelW' in inj and '2*pixelH' in inj

def test_carousel_is_toolbar_width_and_body_contracts_more():
    inj = txt('functions/fn_skInject.sqf')
    assert 'private _toolbarW = safeZoneW / 11;' in inj
    assert 'private _carCompactW = _toolbarW;' in inj
    assert 'private _carExpandedW = _toolbarW;' in inj
    assert 'safeZoneH * 0.22 / _fillV' in inj
    assert 'safeZoneH*0.145' in inj
    assert 'safeZoneH*0.390' in inj

def test_carousel_art_is_larger_inside_tighter_footprint():
    car = txt('functions/fn_skCarouselRender.sqf')
    assert 'if (_expanded) then {1.04} else {1.08}' in car
    assert 'if (_expanded) then {0.42} else {0.38}' in car
    assert '[0.34,0.66,1.0,0.66,0.34]' in car
    assert '[0.28,0.55,1.0,0.55,0.28]' in car
    assert 'if (_expanded) then {0.160} else {0.165}' in car

def test_carousel_has_fading_gray_underlay():
    inj = txt('functions/fn_skInject.sqf')
    layout = txt('functions/fn_skDynamicLayout.sqf')
    assert 'for "_g" from 0 to 14' in inj
    assert '84482 + _g' in inj
    assert 'for "_i" from 0 to 14' in layout
    assert '[0.12,0.12,0.12,_a]' in layout
    assert '0.04 + 0.22 * (1 - _dist)' in layout

def test_patient_header_is_name_only_and_raised_in_body_view():
    car = txt('functions/fn_skCarouselRender.sqf')
    layout = txt('functions/fn_skDynamicLayout.sqf')
    setview = txt('functions/fn_skSetView.sqf')
    assert 'ctrlSetText (if (isNull _p) then {"Patient"} else {name _p})' in car
    assert 'safeZoneY + safeZoneH*0.010' in layout
    assert 'ACME_SK_PatientHeaderNativeRect' in setview
    assert 'format ["%1 %2",_pn' not in car

def test_access_click_is_immediate_selected_syringe_administration():
    site = txt('functions/fn_skSiteClick.sqf')
    inject = txt('functions/fn_skInjectSite.sqf')
    hot = txt('functions/fn_skBuildHotspots.sqf')
    assert '[_part] call ACME_fnc_skInjectSite;' in site
    assert 'ACME_fnc_skSelectedIndex' in inject
    assert 'ACME_SK_CarouselBusy' in hot
    assert '!_carouselBusy' in hot

def test_carousel_motion_has_two_phase_scroll_and_clicks_use_it():
    move = txt('functions/fn_skCarouselMove.sqf')
    pick = txt('functions/fn_skCarouselPick.sqf')
    assert 'private _motion = 0.085;' in move
    assert '_c ctrlCommit _motion;' in move
    assert '[_motion] call ACME_fnc_skCarouselRender;' in move
    assert '[_dir] call ACME_fnc_skCarouselMove;' in pick
    assert 'abs _offset > 1' in pick

def test_single_syringe_only_nudges_and_does_not_duplicate_neighbors():
    move = txt('functions/fn_skCarouselMove.sqf')
    car = txt('functions/fn_skCarouselRender.sqf')
    assert 'if (_n == 1) exitWith' in move
    assert 'private _shift=_dir*_rw*0.070;' in move
    assert '_n == 1 && {_slot != 2}' in car
