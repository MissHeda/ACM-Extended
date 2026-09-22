from historical_source import read_source, assert_release_identity
#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def txt(rel): return read_source(ROOT/rel, encoding='utf-8',errors='ignore')

def test_version():
    assert_release_identity()
    p=txt('functions/fn_postInit.sqf')
    assert_release_identity()
    assert_release_identity()

def test_tag_25():
    c=txt('config.cpp')
    tag=c[c.index('class ACME_SK_TagEdit'):c.index('class ACME_SK_TagText')]
    assert 'maxChars = 25;' in tag
    for f in ['fn_skPendingTagCommit.sqf','fn_skApplyPendingTag.sqf','fn_skTagCommit.sqf','fn_skPendingTagRender.sqf','fn_skCarouselRender.sqf']:
        s=txt('functions/'+f)
        assert 'select [0,17]' not in s and 'select [0, 17]' not in s
    s=txt('functions/fn_skPendingTagRender.sqf')
    assert '_lineH = 0.038' in s and '_lineFontH = 0.0185' in s and '_w*0.230' in s

def test_hover_and_opacity():
    h=txt('functions/fn_skCarouselHover.sqf')
    assert 'ACME_SK_CarouselExpanded",true' in h
    assert '[0.14] call ACME_fnc_skDynamicLayout' in h
    inj=txt('functions/fn_skInject.sqf')
    assert inj.count('[true] call ACME_fnc_skCarouselHover;') >= 2
    r=txt('functions/fn_skCarouselRender.sqf')
    assert '[0.08,0.34,1.0,0.34,0.08]' in r
    assert '_hit ctrlSetTooltip "";' in r
    assert 'ACME_fnc_skSyringeRemembered' in r and '"???"' in r
    m=txt('functions/fn_skCarouselMove.sqf')
    assert '[0.08,0.34,1.0,0.34,0.08]' in m

def test_three_syringe_memory():
    s=txt('functions/fn_skSyringeRemembered.sqf')
    assert '_idx >= ((_n - 3) max 0)' in s
    assert '_color in ["","none"]' in s
    menu=txt('functions/fn_skSyringeSelfMenu.sqf')
    assert 'ACME_fnc_skSyringeRemembered' in menu and '{"???"}' in menu

def test_discard_button():
    i=txt('functions/fn_skInject.sqf')
    assert '84819' in i and '84820' in i and 'ACME_fnc_skBodyActionClick' in i
    r=txt('functions/fn_skBodyActionRender.sqf')
    assert 'Discard Syringe' in r and 'Confirm discard?' in r
    assert '["danger",_a]' in r
    c=txt('functions/fn_skBodyActionClick.sqf')
    assert 'ACME_SK_DiscardArmedId' in c and 'ACME_fnc_skDiscardSelected' in c
    d=txt('functions/fn_skDiscardSelected.sqf')
    assert '_store deleteAt _idx' in d

def test_staged_push():
    s=txt('functions/fn_skBeginInjection.sqf')
    assert 'ACME_SK_PendingInjection' in s
    assert 'ACME_fnc_skConfirmInjection' not in s
    r=txt('functions/fn_skBodyActionRender.sqf')
    assert 'format ["%1 %2 mL in %3",_verb,_mlText,_where]' in r
    assert '_verb = "Push"' in r and 'private _verb = "Inject"' in r
    assert 'ACME_fnc_ivVeinCatalog' in r and 'getOrDefault ["short"' in r
    c=txt('functions/fn_skBodyActionClick.sqf')
    assert 'call ACME_fnc_skConfirmInjection' in c
    q=txt('functions/fn_skConfirmInjection.sqf')
    assert 'ctrlCommit 3.0' in q and 'ACME_SyringePush' in q
    assert 'ACME_SK_PendingInjection",[]' in q

def test_feedback_lingers():
    assert 'Drawn! (%1)' in txt('functions/fn_skCompoundDraw.sqf')
    assert 'Drawn! (%1)' in txt('functions/fn_skWasteDraw.sqf')
    assert '],1.00] call CBA_fnc_waitAndExecute;' in txt('functions/fn_skCompoundDraw.sqf')
    assert '],1.00] call CBA_fnc_waitAndExecute;' in txt('functions/fn_skWasteDraw.sqf')
    assert '],1.10] call CBA_fnc_waitAndExecute;' in txt('functions/fn_skCompoundSave.sqf')
    assert '],1.10] call CBA_fnc_waitAndExecute;' in txt('functions/fn_skFlushSave.sqf')

if __name__=='__main__':
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_')]
    for f in tests: f()
    print(f'B76 focused contracts: {len(tests)}/{len(tests)} passed')
