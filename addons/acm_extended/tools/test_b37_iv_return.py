"""Medical page return contracts plus adversarial navigation scenarios.

These checks do not execute SQF or create an Arma display. The event model makes
expected UI ownership explicit while source contracts bind the implementation to
ACE's one-argument openMenu API and the pre-progress treatment callback.
"""
from dataclasses import dataclass
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(name):
    return (ROOT / 'functions' / f'fn_{name}.sqf').read_text(encoding='utf-8-sig')


@dataclass(frozen=True)
class Page:
    patient: str
    category: str
    body: int


class Navigation:
    def __init__(self):
        self.serial = 0
        self.epoch = 1
        self.session = None
        self.return_page = None
        self.active = None
        self.queue = []
        self.shown = None
        self.flashlight = False
        self.last_menu = 0

    def start(self, page):
        self.serial += 1
        self.session = (page.patient, self.epoch, self.serial)
        self.active = f'iv:{self.serial}'
        self.return_page = page
        self.shown = None
        return self.active

    def close(self, display):
        if display != self.active:
            return
        self.active = None
        if not self.flashlight:
            self.queue.append((self.serial, self.session, self.return_page, self.last_menu))

    def tick(self):
        for serial, session, page, last_menu in self.queue:
            if serial != self.serial or session != self.session or session[1] != self.epoch:
                continue
            if self.active or self.flashlight or last_menu != self.last_menu:
                continue
            self.shown = page
            self.last_menu += 1
        self.queue.clear()


class ReturnScenarios(unittest.TestCase):
    def test_each_peripheral_limb_and_ej_returns_its_launch_page(self):
        for body in (0, 2, 3, 4, 5):
            for category in ('medication', 'advanced'):
                with self.subTest(body=body, category=category):
                    n = Navigation()
                    page = Page('captured casualty', category, body)
                    d = n.start(page)
                    n.close(d)
                    n.tick()
                    self.assertEqual(n.shown, page)

    def test_untouched_partial_and_completed_procedures_share_one_return(self):
        for progress in ('untouched', 'band only', 'threaded', 'connected'):
            with self.subTest(progress=progress):
                n = Navigation()
                page = Page('patient', 'medication', 3)
                d = n.start(page)
                n.close(d)
                n.close(d)
                n.tick()
                self.assertEqual(n.shown, page)
                self.assertEqual(n.last_menu, 1)

    def test_new_session_cancels_old_return_even_for_same_patient(self):
        n = Navigation()
        old = n.start(Page('patient', 'medication', 3))
        n.close(old)
        new = n.start(Page('patient', 'medication', 0))
        n.tick()
        self.assertIsNone(n.shown)
        self.assertEqual(n.active, new)

    def test_obsolete_display_unload_does_not_teardown_new_session(self):
        n = Navigation()
        old = n.start(Page('old', 'medication', 3))
        new = n.start(Page('new', 'medication', 0))
        n.close(old)
        self.assertEqual(n.active, new)
        self.assertEqual(n.queue, [])

    def test_flashlight_close_and_rebuild_retains_original_page(self):
        n = Navigation()
        page = Page('patient', 'medication', 0)
        d = n.start(page)
        n.flashlight = True
        n.close(d)
        n.tick()
        self.assertIsNone(n.shown)
        n.flashlight = False
        n.active = d  # Rebuild keeps the same logical IV session
        n.close(d)
        n.tick()
        self.assertEqual(n.shown, page)

    def test_patient_reset_cancels_return(self):
        n = Navigation()
        d = n.start(Page('patient', 'medication', 3))
        n.close(d)
        n.epoch += 1
        n.tick()
        self.assertIsNone(n.shown)

    def test_later_menu_selection_is_never_restamped(self):
        n = Navigation()
        d = n.start(Page('patient', 'medication', 3))
        n.close(d)
        n.last_menu += 1
        later = Page('other patient', 'examine', 1)
        n.shown = later
        n.tick()
        self.assertEqual(n.shown, later)

    def test_another_active_display_wins(self):
        n = Navigation()
        d = n.start(Page('patient', 'medication', 3))
        n.close(d)
        n.active = 'other addon display'
        n.tick()
        self.assertIsNone(n.shown)


class ReturnSourceContracts(unittest.TestCase):
    def test_callback_captures_before_progress_can_close_menu(self):
        cfg = (ROOT / 'config.cpp').read_text(encoding='utf-8-sig')
        self.assertIn('class ivMinigamePrepare {};', cfg)
        for name in ('ACME_IVMinigameStart', 'ACME_EstablishEJ'):
            block = cfg.split('class ' + name + ':', 1)[1].split('\n    };', 1)[0]
            self.assertIn('callbackStart = "_this call ACME_fnc_ivMinigamePrepare"', block)
        prep = source('ivMinigamePrepare')
        for variable in ('ace_medical_gui_target', 'ace_medical_gui_selectedCategory', 'ace_medical_gui_selectedBodyPart'):
            self.assertIn(variable, prep)
        self.assertIn('isEqualTo _patient', prep)
        self.assertIn('ACME_IV_PreparedMenu', prep)

    def test_done_closes_owned_display_and_never_schedules_another_return(self):
        done = source('ivMinigameDone')
        self.assertIn('_display closeDisplay 1', done)
        self.assertIn('ACME_IV_Done', done)
        self.assertIn('ACME_fnc_aceCursorRestore', done)
        for bad in ('closeDialog', 'CBA_fnc_wait', 'openMenu', 'selectedCategory', 'debug_lastTreatmentTarget'):
            self.assertNotIn(bad, done)
        self.assertEqual(source('ivMinigameClose').count('call ACME_fnc_reopenMedicalMenu'), 1)

    def test_owner_metadata_survives_flashlight_rebuild(self):
        init = source('ivMinigameInit')
        close = source('ivMinigameClose')
        for key in ('ACME_IV_Session', 'ACME_IV_ReturnMenu'):
            self.assertIn(f'_display setVariable ["{key}"', init)
            self.assertNotIn(f'uiNamespace setVariable ["{key}", []]', close)
        self.assertIn('_closing isNotEqualTo _active', close)
        self.assertIn('[_session] call ACME_fnc_ivUiValid', close)
        cfg = (ROOT / 'config.cpp').read_text(encoding='utf-8-sig')
        self.assertIn('onUnload = "_this call ACME_fnc_ivMinigameClose"', cfg)

    def test_all_iv_locations_use_captured_context_and_suppress_native_reopen(self):
        opening = source('ivMinigameOpen')
        self.assertIn('== "ej") then {"head"}', opening)
        self.assertIn('["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]', opening)
        self.assertIn('_return = +(_prepared select 3)', opening)
        self.assertIn('ace_medical_gui_pendingReopen = false', opening)
        self.assertIn('ACME_medicalReturnSerial', opening)
        self.assertIn('CBA_missionTime - (_prepared select 5) <= 5', opening)

    def test_native_open_signature_and_exact_selection(self):
        reopen = source('reopenMedicalMenu')
        self.assertEqual(reopen.count('call ace_medical_gui_fnc_openMenu'), 1)
        self.assertIn('[_patient] call ace_medical_gui_fnc_openMenu', reopen)
        self.assertLess(reopen.index('selectedCategory = _category'), reopen.index('call ace_medical_gui_fnc_openMenu'))
        self.assertLess(reopen.index('selectedBodyPart = _bodyPart'), reopen.index('call ace_medical_gui_fnc_openMenu'))
        self.assertNotIn('ACM_gui_lastSelectedCategory', reopen)
        self.assertEqual(reopen.count('CBA_fnc_waitAndExecute'), 1)

    def test_deferred_return_checks_session_and_new_ui_before_selection(self):
        reopen = source('reopenMedicalMenu')
        guard_end = reopen.index('ace_medical_gui_selectedCategory = _category')
        for guard in ('ACME_medicalReturnSerial', 'ACME_fnc_ivUiValid', 'ace_medical_gui_lastOpenedOn',
                      'ACME_minigame_reopen', 'ACME_flashlightMenuActive', 'ACME_minigame_open',
                      'ace_interact_menu_cursorMenuOpened', 'allDisplays findIf', 'ace_medical_gui_fnc_canOpenMenu'):
            self.assertIn(guard, reopen[:guard_end])
        self.assertGreaterEqual(reopen.count('ACME_minigame_reopen'), 2)
        self.assertGreaterEqual(reopen.count('ACME_flashlightMenuActive'), 2)

    def test_returns_do_not_depend_on_death_or_placement_completion(self):
        for name in ('ivMinigamePrepare', 'ivMinigameDone', 'reopenMedicalMenu'):
            s = source(name)
            for bad in ('alive _patient', 'ACME_IV_Stage', 'ACME_IV_InsFrame', 'ACM_circulation_IV_Placement'):
                self.assertNotIn(bad, s)
        self.assertIn('ACME_fnc_ivMinigameSaveState', source('ivMinigameClose'))

    def test_dropdown_cache_and_treatment_state_are_not_overwritten(self):
        for name in ('ivMinigamePrepare', 'ivMinigameDone', 'reopenMedicalMenu'):
            s = source(name)
            for bad in ('ACME_menuOpen', 'menuDropdownState', 'remoteExec', 'CBA_fnc_globalEvent', 'displayTextStructured'):
                self.assertNotIn(bad, s)


if __name__ == '__main__':
    unittest.main()
