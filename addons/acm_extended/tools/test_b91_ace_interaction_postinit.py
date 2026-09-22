"""ACE-interaction regressions across the actual split startup modules.

B92's old literal version and monolithic placement are not release criteria.
No production code is changed by these checks.
"""
from pathlib import Path
from historical_source import assert_release_identity, read_source, source_bundle
from source_scan import lex

ROOT = Path(__file__).resolve().parents[1]
POST = ROOT / "functions/fn_postInit.sqf"


def test_release_identity_is_consistent():
    assert_release_identity()


def test_no_accidental_bare_flashlight_comment():
    for path, text in source_bundle(POST):
        assert '\n the flashlight filter flag must never strand ACE.' not in text, path


def test_flashlight_filter_has_close_and_watchdog_cleanup():
    text = read_source(POST)
    for token in ('["notOnMap", {', 'call ace_common_fnc_addCanInteractWithCondition;',
                  '["ace_interactMenuClosed", {', 'missionNamespace setVariable ["ACME_flashlightMenuActive", false];',
                  'call CBA_fnc_addPerFrameHandler;'):
        assert token in text, token


def test_retired_flashlight_diagnostics_stay_retired():
    # The original whole-postInit ban also caught legitimate unrelated compatibility
    # diagnostics. Restrict to the actual module installing the flashlight filter.
    modules = [(p,t) for p,t in source_bundle(POST) if '["notOnMap", {' in t]
    assert len(modules) == 1
    values = {t.value for t in lex(modules[0][1]) if t.kind == 'ident'}
    assert not values.intersection({'diag_log', 'systemChat', 'hintSilent', 'ACME_flashlight_diag'})


def test_each_startup_module_has_balanced_delimiters():
    pairs = {')': '(', ']': '[', '}': '{'}
    for path, text in source_bundle(POST):
        stack = []
        for token in lex(text):
            if token.kind != 'symbol':
                continue
            if token.value in ('(', '[', '{'):
                stack.append(token.value)
            elif token.value in pairs:
                assert stack and stack.pop() == pairs[token.value], (path, token.line)
        assert not stack, path
