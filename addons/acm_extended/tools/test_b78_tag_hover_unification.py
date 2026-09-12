#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def txt(rel): return (ROOT/rel).read_text(encoding='utf-8',errors='ignore')

def test_version():
    assert 'version = "1.0.100-r42";' in txt('config.cpp')
    p=txt('functions/fn_postInit.sqf')
    assert 'ACME_infusion_version = "1.0.100-r42"' in p
    assert 'ACME_buildBatch = "B78";' in p

def test_tag_font_and_capacity():
    c=txt('config.cpp')
    tag=c[c.index('class ACME_SK_TagEdit'):c.index('class ACME_SK_TagText')]
    assert 'maxChars = 25;' in tag
    for rel in ['functions/fn_skPendingTagCommit.sqf','functions/fn_skApplyPendingTag.sqf','functions/fn_skTagCommit.sqf','functions/fn_skPendingTagRender.sqf','functions/fn_skCarouselRender.sqf']:
        s=txt(rel)
        assert 'select [0,17]' not in s and 'select [0, 17]' not in s
    p=txt('functions/fn_skPendingTagRender.sqf')
    r=txt('functions/fn_skCarouselRender.sqf')
    assert '_lineFontH = 0.031' in p and '_lineFontH = 0.031' in r
    assert '_lineH = 0.038' in p and '_lineH = 0.038' in r
    assert '_w*0.245' in p and '_w*0.245' in r and '_aw*0.245' in r

def test_selector_geometry_unified():
    p=txt('functions/fn_skPendingTagRender.sqf')
    e=txt('functions/fn_skPendingTagEnsure.sqf')
    r=txt('functions/fn_skCarouselRender.sqf')
    compact='((_textW + 12*pixelW) max (safeZoneH*0.090)) min (safeZoneH*0.145)'
    assert compact in p and compact in r
    assert '_tagCenterX = _x + _w*0.36' in p
    assert '_tagCenterX0 = (_r0 select 0) + (_r0 select 2)*0.36' in e
    assert '_tagCenterX = _ax + _aw*0.36' in r
    for s in (p,r):
        assert 'private _menuW = (safeZoneW * 0.24) min (safeZoneH * 0.78);' in s
        assert 'private _menuY = _btnY + _btnH + 2*pixelH;' in s
        assert 'ctrlSetBackgroundColor [0.04,0.04,0.04,0.96]' in s

def test_click_only_dropdowns():
    pend=txt('functions/fn_skPendingTagEnsure.sqf')
    inj=txt('functions/fn_skInject.sqf')
    assert '_button ctrlAddEventHandler ["ButtonClick"' in pend
    assert 'B74: click is the ONLY toggle' in pend
    assert '_colorBtn ctrlAddEventHandler ["ButtonClick"' in inj
    # Neither selector gets a hover handler that opens/closes its list.
    assert '_button ctrlAddEventHandler ["MouseEnter"' not in pend
    color_chunk=inj[inj.index('private _colorBtn'):inj.index('private _colorList')]
    assert 'ctrlShow true' not in color_chunk or 'ButtonClick' in color_chunk

def test_hover_is_visual_only():
    h=txt('functions/fn_skCarouselHover.sqf')
    r=txt('functions/fn_skCarouselRender.sqf')
    i=txt('functions/fn_skInject.sqf')
    assert 'ACME_SK_CarouselExpanded",true' not in h
    assert 'skDynamicLayout' not in h
    assert 'skCarouselRender' in h
    assert 'ACME_SK_CarouselHoverOffset' in i and 'ACME_SK_CarouselHoverOffset' in r
    assert 'if (!_editMode && {_off == _hoverOffset}) then {_alpha = 1;};' in r
    assert '_hit ctrlSetTooltip "";' in r
    assert '_activeHit ctrlSetTooltip _activeTip;' in r

def test_expansion_still_click_or_ad():
    pick=txt('functions/fn_skCarouselPick.sqf')
    move=txt('functions/fn_skCarouselMove.sqf')
    inj=txt('functions/fn_skInject.sqf')
    assert 'call ACME_fnc_skCarouselToggle' in pick
    assert 'ACME_SK_CarouselExpanded",true' in move
    assert '[_dir] call ACME_fnc_skCarouselMove;' in inj

if __name__=='__main__':
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_')]
    for f in tests: f()
    print(f'B78 focused contracts: {len(tests)}/{len(tests)} passed')
