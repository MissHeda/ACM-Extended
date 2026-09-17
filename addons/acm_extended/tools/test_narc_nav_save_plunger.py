from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(rel): return (ROOT/rel).read_text(encoding='utf-8', errors='ignore')

def test_save_is_in_place_and_immediate():
    s=read('functions/fn_skCompoundSave.sqf')
    assert 'closeDialog 0' not in s
    assert 'ACME_fnc_skOpenDraw' not in s
    assert '[] call ACME_fnc_skCompoundBegin;' in s
    assert '0.45] call CBA_fnc_waitAndExecute;' in s

def test_size_switch_is_in_place():
    p=read('functions/fn_skPickSize.sqf')
    a=read('functions/fn_skApplySize.sqf')
    assert 'closeDialog 0' not in p
    assert 'ACME_fnc_skOpenDraw' not in p
    assert 'ACME_fnc_skApplySize' in p
    assert 'for "_id" from 84010 to 84021' in a
    assert 'ACM_circulation_SyringeDraw_Ctrl_LimitTop' in a

def test_three_page_navigation_and_dual_buttons():
    i=read('functions/fn_skInject.sqf')
    sv=read('functions/fn_skSetView.sqf')
    nav=read('functions/fn_skPageNavigate.sqf')
    assert '84152' in i and '84157' in i
    assert '"< Transfuse"' in i and '"Body Map >"' in i
    assert '"< Narc Box"' in sv and '"Transfuse >"' in sv
    assert 'ACM_circulation_fnc_openTransfusionMenu' in nav
    assert 'ACME_SK_RequestedView' in nav

def test_push_uses_frame_interpolation():
    c=read('functions/fn_skConfirmInjection.sqf')
    r=read('functions/fn_skCarouselRender.sqf')
    assert 'ACME_SK_PushAnimPFH' in c
    assert 'private _e = _t * _t * (3 - (2 * _t));' in c
    assert 'ctrlCommit _pushSec' not in c
    assert '_injectBusy && {_slot == 2}' in r

def test_chrom_duplicate_reference_restored():
    t=read('functions/fn_visualFxTick.sqf')
    assert '_acmKetChrom ppEffectEnable false;' in t
    assert 'former dose/HR-synchronous contribution numerically below' in t
