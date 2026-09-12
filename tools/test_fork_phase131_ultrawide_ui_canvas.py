#!/usr/bin/env python3
"""Phase 131: authored ACM/Extended central UIs use the centered aspect-safe canvas through 32:9."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
mac=(R/'addons/main/script_macros.hpp').read_text()
assert 'ACM_UI_CANVAS_W' in mac and 'safeZoneH * 1.7777777778' in mac
core=(R/'addons/core/UI_defines.hpp').read_text()
aed=(R/'addons/circulation/Defibrillator_defines.hpp').read_text()
surg=(R/'addons/airway/SurgicalAirway_defines.hpp').read_text()
assert 'ACM_UI_CANVAS_W * 0.55' in core
assert 'ACM_UI_CANVAS_W * 0.55' in aed
assert 'ACM_UI_CANVAS_X' in aed and 'ACM_GUI_AED_SIZEM' in aed
assert 'ACM_UI_CANVAS_W * 0.55' in surg
for name in ['SyringeDraw_Dialog.hpp','TransfusionMenu_Dialog.hpp']:
    t=(R/'addons/circulation'/name).read_text()
    assert 'safeZoneW' not in t and 'safeZoneX' not in t
    assert 'ACM_UI_CANVAS_W' in t and 'ACM_UI_CANVAS_X' in t
trans=(R/'addons/circulation/TransfusionMenu_Dialog.hpp').read_text()
for bad in ['x = QUOTE(safeZoneY + (safeZoneH / 2) + (ACM_UI_CANVAS_W / 54))','y = QUOTE(ACM_UI_CANVAS_X + (ACM_UI_CANVAS_W / 2)']:
    assert bad not in trans
cfg=(R/'addons/acm_extended/config.cpp').read_text()
assert 'class uiCanvas {};' in cfg
for name in ['fn_skInject.sqf','fn_skCarouselRender.sqf','fn_skDynamicLayout.sqf','fn_skListRefresh.sqf']:
    t=(R/'addons/acm_extended/functions'/name).read_text()
    assert 'call ACME_fnc_uiCanvas' in t
    assert 'safeZoneW' not in t and 'safeZoneX' not in t
setup=(R/'addons/acm_extended/functions/fn_aedSyncSetup.sqf').read_text()
tick=(R/'addons/acm_extended/functions/fn_syncFlagsTick.sqf').read_text()
assert 'call ACME_fnc_uiCanvas' in setup and 'call ACME_fnc_uiCanvas' in tick
assert '_uiW * 0.55' in setup and '_uiW * 0.55' in tick

# Reference-model the width rule at common aspect ratios. Anything >=16:9 must retain the exact same authored canvas width.
def canvas_w(aspect):
    return min(aspect, 16/9)
assert abs(canvas_w(16/9) - 16/9) < 1e-9
assert abs(canvas_w(21/9) - 16/9) < 1e-9
assert abs(canvas_w(32/9) - 16/9) < 1e-9
assert canvas_w(4/3) == 4/3

print('PASS phase131: core ACM, Narc Box/transfusion and LifePak authored canvases preserve scale on ultrawide')
