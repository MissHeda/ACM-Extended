"""IV input regression contracts; these inspect SQF and do not run Arma UI events.

CBA addDisplayHandler delivers events from the main display. The B33 router
started rejecting that fallback because it requires the current IV display.
Keep the source adaptation in the narrow CBA adapter, not in the common router.
"""
import unittest

from test_b33_boa_input import block_after, source
from test_na8_5_batch10 import InputModel, binding


class MiddleClickFallback(unittest.TestCase):
    def test_cba_press_and_release_adapt_main_display_before_routing(self):
        text = source('ivMinigameInit')
        for anchor, target in (
            ('private _mbId = ["MouseButtonDown",', 'ivMinigameClick'),
            ('private _mbUpId = ["MouseButtonUp",', 'ivMinigameRelease'),
        ):
            route, _, _ = block_after(text, anchor)
            with self.subTest(target=target):
                self.assertIn('private _event = +_this;', route)
                self.assertIn('_event set [0, _dialog];', route)
                dispatch = f'_event call ACME_fnc_{target}'
                self.assertLess(route.index('_event set [0, _dialog]'), route.index(dispatch))
                # Do not pass the unadapted source through the input bridge.
                self.assertNotIn('_this call ACME_fnc_' + target, route)
                self.assertNotIn('[_this,"down"]', route)

    def test_only_middle_can_cross_main_display_adapter_for_valid_session(self):
        text = source('ivMinigameInit')
        for anchor in ('private _mbId = ["MouseButtonDown",', 'private _mbUpId = ["MouseButtonUp",'):
            route, _, _ = block_after(text, anchor)
            self.assertIn('if (_button != 2) exitWith { false };', route)
            self.assertIn('isNull _dialog || {!([] call ACME_fnc_ivUiValid)}', route)
            self.assertLess(route.index('if (_button != 2)'), route.index('_event set'))
        # Retain strict ownership of ordinary input; do not accept arbitrary displays.
        self.assertIn('_display != (uiNamespace getVariable ["ACME_IV_DLG", displayNull])', source('ivMinigameClick'))

    def test_controls_forward_release_as_well_as_press(self):
        text = source('ivMinigameInit')
        release, _, _ = block_after(text, 'private _fnc_ivMBUp =')
        self.assertIn('_this call ACME_fnc_ivMinigameRelease', release)
        self.assertIn('_x ctrlAddEventHandler ["MouseButtonUp", _fnc_ivMBUp]', text)
        dynamic = source('ivMinigameHookCtrl')
        self.assertIn('_ctrl ctrlAddEventHandler ["MouseButtonUp", _mbUp]', dynamic)
        self.assertIn('ACME_IV_MBUpHandler', dynamic)
        for name in ('ivMinigameInsertStart', 'ivCathSetFrame', 'ivMinigameRenderMarks'):
            self.assertIn('call ACME_fnc_ivMinigameHookCtrl', source(name))

    def test_rebound_middle_input_can_release_and_repeat_once_per_press(self):
        # Control, dialog and fallback can all observe a physical event. The
        # matching release must reach their shared dialog input state too.
        model = InputModel()
        binds = [binding(2, device='MOUSE_BUTTON')]
        for frame in (1, 2):
            for _ in range(3):
                self.assertTrue(model.event(2, binds, frame=frame, device='MOUSE_BUTTON'))
            for _ in range(3):
                self.assertTrue(model.event(2, binds, up=True, frame=frame, device='MOUSE_BUTTON'))
        self.assertEqual(model.actions, ['nv', 'nv'])
        self.assertEqual(model.held, {})

    def test_close_removes_both_main_display_handlers(self):
        text = source('ivMinigameClose')
        for event, variable, handler in (
            ('MouseButtonDown', '_mbId', 'ACME_IV_MBDisplayHandler'),
            ('MouseButtonUp', '_mbUpId', 'ACME_IV_MBUpDisplayHandler'),
        ):
            self.assertIn(f'["{event}", {variable}] call CBA_fnc_removeDisplayHandler', text)
            self.assertIn(f'uiNamespace setVariable ["{handler}", -1]', text)

    def test_physical_withdrawal_keeps_state_guards_and_keyboard_fallback(self):
        retract = source('ivMinigameRetract')
        self.assertIn('if (_stage0 != "thread") exitWith', retract)
        self.assertIn('getVariable ["ACME_IV_InsFrame", 6]) < 11', retract)
        self.assertIn('_context call ACME_fnc_ivMinigameViewValid', retract)
        self.assertIn('call ACME_fnc_ivMinigameStickSuccess', retract)
        init = source('ivMinigameInit')
        key, _, _ = block_after(init, '_display displayAddEventHandler ["KeyDown",')
        self.assertIn('getVariable ["ACME_iv_keyWithdraw", 57]', key)
        self.assertIn('[] call ACME_fnc_ivMinigameRetract', key)


if __name__ == '__main__':
    unittest.main()
