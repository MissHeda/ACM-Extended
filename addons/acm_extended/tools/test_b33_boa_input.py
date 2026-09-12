"""Offline input routing contracts. Does not execute SQF or simulate Arma events."""
from pathlib import Path
import unittest

from source_scan import lex, matching

ROOT = Path(__file__).resolve().parents[1]


def source(name):
    return (ROOT / 'functions' / ('fn_' + name + '.sqf')).read_text(encoding='utf-8')


def block_after(text, anchor):
    start = text.index('{', text.index(anchor) + len(anchor))
    tokens = lex(text)
    index = next(i for i, token in enumerate(tokens) if token.offset == start)
    end = tokens[matching(tokens)[index]].offset
    return text[start + 1:end], start, end


class BoaInputRoutes(unittest.TestCase):
    def test_band_removal_only_exists_in_secondary_button_branch(self):
        text = source('ivMinigameClick')
        branch, start, end = block_after(text, 'if (_button in [1, 2]) exitWith')
        call = 'call ACME_fnc_ivMinigameRemoveBand'
        self.assertEqual(text.count(call), 1)
        self.assertIn(call, branch)
        self.assertNotIn(call, text[:start] + text[end + 1:])
        gate, _, _ = block_after(branch, 'if (_button == 1')
        # The condition includes lazy blocks, so inspect the complete band gate.
        self.assertIn('ACME_IV_BandOn', gate)
        self.assertIn('ACME_IV_EJMode', branch)
        self.assertLess(branch.index('if (_hitBand) exitWith'), branch.index('call ACME_fnc_ivMinigameRetract'))

    def test_control_and_cba_secondary_routes_share_display_hit_test(self):
        text = source('ivMinigameInit')
        control, _, _ = block_after(text, 'private _fnc_ivMB =')
        cba, _, _ = block_after(text, 'private _mbId = ["MouseButtonDown",')
        self.assertIn('_this call ACME_fnc_ivMinigameClick', control)
        self.assertIn('_event call ACME_fnc_ivMinigameClick', cba)
        for route in (control, cba):
            self.assertNotIn('ACME_fnc_ivMinigameRetract', route)
        self.assertIn('_display = ctrlParent _display', source('ivMinigameClick'))
        self.assertIn('ACME_IV_MBHandler', source('ivMinigameHookCtrl'))

    def test_duplicate_secondary_delivery_cannot_remove_then_retract(self):
        branch, _, _ = block_after(source('ivMinigameClick'), 'if (_button in [1, 2]) exitWith')
        self.assertIn('private _press = [diag_frameNo, _button]', branch)
        self.assertIn('isEqualTo _press) exitWith {true}', branch)
        self.assertLess(branch.index('setVariable ["ACME_IV_SecondaryPress", _press]'), branch.index('private _hitBand'))

    def test_removal_ends_hold_without_discarding_tool_or_insertion(self):
        tokens = lex(source('ivMinigameRemoveBand'))
        text = source('ivMinigameRemoveBand')
        self.assertIn('["ACME_IV_Dragging", false]', text)
        self.assertNotIn('ACME_IV_Held', [token.value for token in tokens])
        self.assertFalse(any(token.kind == 'string' and token.value.startswith('ACME_IV_Ins') for token in tokens))
        self.assertIn('[false] call ACME_fnc_ivMinigameBandFlag', text)
        self.assertIn('call ACME_fnc_ivMinigameSaveState', text)

    def test_release_cannot_remove_band_or_end_unrelated_left_hold(self):
        text = source('ivMinigameRelease')
        self.assertNotIn('ACME_fnc_ivMinigameRemoveBand', text)
        self.assertLess(text.index('if (_button != 0) exitWith'), text.index('["ACME_IV_Dragging", false]'))
        self.assertIn('[false] call ACME_fnc_ivMinigamePullStop', text)


if __name__ == '__main__':
    unittest.main()
